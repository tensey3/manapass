import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../data/repositories/question_repository.dart';

class WrongQuestion {
  final String id;
  final String category; // カードバッジ表示用（例: 科目A・コンピュータシステム / 科目B）
  final String filterKey; // 苦手分野絞り込み用（例: コンピュータシステム / 科目B）
  final String text;
  final String userChoice;
  final String correctAnswer;
  final String? explanation;

  const WrongQuestion({
    required this.id,
    required this.category,
    required this.filterKey,
    required this.text,
    required this.userChoice,
    required this.correctAnswer,
    this.explanation,
  });
}

class WeakArea {
  final String category;
  final int correct;
  final int total;

  const WeakArea({
    required this.category,
    required this.correct,
    required this.total,
  });

  double get accuracy => total == 0 ? 0 : correct / total;
}

class ReviewData {
  final List<WrongQuestion> wrong;
  final List<WeakArea> weakAreas;

  const ReviewData({
    required this.wrong,
    required this.weakAreas,
  });
}

abstract class ReviewDataSource {
  Future<ReviewData> load();
}

class DemoReviewDataSource implements ReviewDataSource {
  const DemoReviewDataSource();

  @override
  Future<ReviewData> load() async => const ReviewData(
    weakAreas: [
      WeakArea(category: 'ネットワーク', correct: 2, total: 8),
      WeakArea(category: 'データベース', correct: 4, total: 9),
      WeakArea(category: 'セキュリティ', correct: 5, total: 10),
    ],
    wrong: [
      WrongQuestion(
        id: 'q1',
        category: '科目A・ネットワーク',
        filterKey: 'ネットワーク',
        text: 'TCP/IPの階層で、IPアドレスによる経路選択を行うのはどれか。',
        userChoice: 'トランスポート層',
        correctAnswer: 'インターネット層',
        explanation: 'IPアドレスで宛先を判断して経路を選ぶのはインターネット層（ネットワーク層）です。',
      ),
    ],
  );
}

class FirestoreReviewDataSource implements ReviewDataSource {
  FirestoreReviewDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    QuestionRepository? questions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _questions = questions ?? QuestionRepository(firestore, auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  // 問題はアプリの中のファイルから読む（解答の記録だけ Firestore）
  final QuestionRepository _questions;

  List<String> _readStringList(Object? raw) {
    if (raw is List) {
      return List<String>.from(
        raw.map((e) => e?.toString() ?? ''),
        growable: false,
      );
    }
    if (raw is String && raw.isNotEmpty) {
      return List<String>.from(raw.split('|||'), growable: false);
    }
    return const <String>[];
  }

  int _readInt(Object? raw, {int fallback = 0}) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
    return fallback;
  }

  String _readString(Object? raw, {String fallback = ''}) {
    if (raw == null) return fallback;
    return raw.toString();
  }

  /// 苦手分野カードの表示名・絞り込みキー。
  /// topic が入っていれば topic、なければ subject、それもなければ category（→ その他）。
  String _resolveAreaLabel(Map<String, dynamic> qData) {
    final topic = _readString(qData['topic'], fallback: '').trim();
    if (topic.isNotEmpty) return topic;

    final subject = _readString(qData['subject'], fallback: '').trim();
    if (subject.isNotEmpty) return subject;

    final category = _readString(qData['category'], fallback: '').trim();
    if (category.isNotEmpty) return category;

    return 'その他';
  }

  /// 間違えた問題カード側のバッジ表記。
  /// subject と topic を組み合わせ、片方しか無ければある方だけを表示する。
  String _resolveCardBadge(Map<String, dynamic> qData) {
    final subject = _readString(qData['subject'], fallback: '').trim();
    final topic = _readString(qData['topic'], fallback: '').trim();

    if (subject.isNotEmpty && topic.isNotEmpty && subject != topic) {
      return '$subject・$topic';
    }
    if (subject.isNotEmpty) return subject;
    if (topic.isNotEmpty) return topic;

    final category = _readString(qData['category'], fallback: '').trim();
    return category.isNotEmpty ? category : 'その他';
  }

  int _resolveAnswerIndex(Map<String, dynamic> data, List<String> choices) {
    final rawIdx = data['answerIndex'] ?? data['correctIndex'] ?? data['correct_index'];
    if (rawIdx != null) {
      final idx = _readInt(rawIdx, fallback: -1);
      if (idx >= 0 && idx < choices.length) return idx;
    }

    final rawAnswer = data['answer']?.toString().trim() ?? '';
    const symbols = ['ア', 'イ', 'ウ', 'エ', 'オ', 'カ', 'キ', 'ク'];
    final symIdx = symbols.indexOf(rawAnswer);
    if (symIdx >= 0 && symIdx < choices.length) return symIdx;

    return 0;
  }

  String _choiceAt(List<String> choices, int index, {String fallback = ''}) {
    if (index < 0 || index >= choices.length) return fallback;
    return choices[index];
  }

  @override
  Future<ReviewData> load() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const ReviewData(wrong: <WrongQuestion>[], weakAreas: <WeakArea>[]);
    }

    final progressSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('questionProgress')
        .get();

    if (progressSnap.docs.isEmpty) {
      return const ReviewData(wrong: <WrongQuestion>[], weakAreas: <WeakArea>[]);
    }

    final progressById = <String, Map<String, dynamic>>{};
    final ids = <String>[];

    for (final doc in progressSnap.docs) {
      final raw = doc.data();
      final map = <String, dynamic>{};
      for (final entry in raw.entries) {
        map[entry.key.toString()] = entry.value;
      }
      progressById[doc.id] = map;
      ids.add(doc.id);
    }

    final questionsById = <String, Map<String, dynamic>>{
      for (final q in await _questions.fetchQuestionsByIds(ids)) q.id.toString(): q.toMap(),
    };

    final wrongList = <WrongQuestion>[];
    final totalsByArea = <String, int>{};
    final correctsByArea = <String, int>{};

    for (final id in ids) {
      final prog = progressById[id];
      final qData = questionsById[id];
      if (prog == null || qData == null) continue;

      final attempts = _readInt(prog['attempts'], fallback: 0);
      final wrongCount = _readInt(prog['wrongCount'], fallback: 0);
      final needsReview = prog['needsReview'] == true;
      final lastWrongIndex = _readInt(prog['lastWrongAnswerIndex'], fallback: -1);

      final areaLabel = _resolveAreaLabel(qData);
      final cardBadge = _resolveCardBadge(qData);

      final safeAttempts = attempts > 0 ? attempts : (wrongCount > 0 ? wrongCount : 1);
      final safeWrong = wrongCount.clamp(0, safeAttempts);
      final safeCorrect = (safeAttempts - safeWrong).clamp(0, safeAttempts);

      totalsByArea[areaLabel] = (totalsByArea[areaLabel] ?? 0) + safeAttempts;
      correctsByArea[areaLabel] = (correctsByArea[areaLabel] ?? 0) + safeCorrect;

      if (needsReview) {
        final choices = _readStringList(qData['choices'] ?? qData['options']);
        final text = _readString(
          qData['question'] ?? qData['questionText'] ?? qData['question_text'],
          fallback: '',
        );
        final correctIdx = _resolveAnswerIndex(qData, choices);
        final explanation = _readString(qData['explanation'], fallback: '');

        wrongList.add(
          WrongQuestion(
            id: id,
            category: cardBadge,
            filterKey: areaLabel,
            text: text,
            userChoice: _choiceAt(choices, lastWrongIndex, fallback: '未回答'),
            correctAnswer: _choiceAt(choices, correctIdx, fallback: ''),
            explanation: explanation.isEmpty ? null : explanation,
          ),
        );
      }
    }

    final weakAreas = <WeakArea>[
      for (final entry in totalsByArea.entries)
        WeakArea(
          category: entry.key,
          correct: correctsByArea[entry.key] ?? 0,
          total: entry.value,
        ),
    ]..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    return ReviewData(
      wrong: wrongList,
      weakAreas: weakAreas,
    );
  }
}