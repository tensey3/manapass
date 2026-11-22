import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';

/// 1回分の試験（問題一覧の1行）。assets/questions/index.json に書いてある。
class ExamInfo {
  const ExamInfo({
    required this.id,
    required this.file,
    required this.year,
    required this.subject,
    required this.title,
    required this.count,
  });

  final String id; // 例: 2025r07_a
  final String file; // 例: 2025r07_a.json
  final int year;
  final String subject; // 科目A / 科目B
  final String title; // 例: 令和7年度 公開問題
  final int count;

  factory ExamInfo.fromMap(Map<String, dynamic> map) => ExamInfo(
        id: map['id'].toString(),
        file: map['file'].toString(),
        year: (map['year'] as num).toInt(),
        subject: map['subject'].toString(),
        title: map['title'].toString(),
        count: (map['count'] as num).toInt(),
      );
}

/// アプリの中に入っている全部の問題。
class _QuestionBank {
  _QuestionBank(this.exams, this.all) : byId = {for (final q in all) q.id.toString(): q};

  final List<ExamInfo> exams;
  final List<Question> all;
  final Map<String, Question> byId;
}

// Riverpod の Provider 定義
final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository();
});

// 復習用のデータ構造
class ReviewEntry {
  final Question question;
  final int lastWrongAnswerIndex;
  ReviewEntry({required this.question, required this.lastWrongAnswerIndex});
}

/// 1問ぶんの解答の記録（users/{uid}/questionProgress/{問題ID}）。
class AnswerRecord {
  const AnswerRecord({
    required this.questionId,
    required this.attempts,
    required this.wrongCount,
    this.lastAnsweredAt,
    this.lastAnsweredCorrectly,
  });

  final String questionId;
  final int attempts;
  final int wrongCount;
  final DateTime? lastAnsweredAt;
  final bool? lastAnsweredCorrectly;
}

class QuestionHistoryEntry {
  const QuestionHistoryEntry({
    required this.question,
    required this.attempts,
    required this.wrongCount,
  });

  final Question question;
  final int attempts;
  final int wrongCount;

  int get correctCount => attempts - wrongCount;
}

class QuestionRepository {
  // 解答の記録だけ Firestore に保存する。問題そのものはアプリの中のファイルから読む。
  // （Firestore の無料枠は読み取り1日5万回まで。全問題を毎回 Firestore から読むと
  //   問題が増えたときにすぐ上限になり、アプリが使えなくなるため）
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;
  final AssetBundle _assets;

  QuestionRepository([FirebaseFirestore? firestore, FirebaseAuth? auth, AssetBundle? assets])
      : _firestoreOverride = firestore,
        _authOverride = auth,
        _assets = assets ?? rootBundle;

  // 問題を読むだけなら Firebase は要らない（テストでも使えるように、必要になったときに取る）
  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  static const _dir = 'assets/questions';

  // 一度読んだら覚えておく（どの画面から呼んでも、ファイルを読むのは1回だけ）
  static final Map<AssetBundle, Future<_QuestionBank>> _cache = {};

  Future<_QuestionBank> _bank() {
    return _cache.putIfAbsent(_assets, () async {
      try {
        final index = jsonDecode(await _assets.loadString('$_dir/index.json')) as Map<String, dynamic>;
        final exams = (index['exams'] as List)
            .map((e) => ExamInfo.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        final all = <Question>[];
        for (final exam in exams) {
          final list = jsonDecode(await _assets.loadString('$_dir/${exam.file}')) as List;
          all.addAll(list.map((raw) => Question.fromMap(Map<String, dynamic>.from(raw as Map))));
        }
        return _QuestionBank(exams, all);
      } catch (_) {
        // 失敗したら覚えない（次に呼んだときにもう一度読む）
        _cache.remove(_assets);
        rethrow;
      }
    });
  }

  List<String> _toStringList(Object? raw) {
    if (raw is List) {
      return List<String>.from(
        raw.map((e) => e?.toString() ?? ''),
        growable: false,
      );
    }
    if (raw is String) {
      return List<String>.from(raw.split('|||'), growable: false);
    }
    return const <String>[];
  }

  Object? _normalizeValue(Object? value) {
    if (value is Map) {
      final map = <String, dynamic>{};
      for (final entry in value.entries) {
        map[entry.key.toString()] = _normalizeValue(entry.value);
      }
      return map;
    }
    if (value is Iterable) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }

  Map<String, dynamic> _asMap(Object? raw, {String? docId}) {
    final map = <String, dynamic>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final key = entry.key.toString();
        final val = entry.value;
        if (key == 'choices' || key == 'options') {
          map[key] = _toStringList(val);
        } else {
          map[key] = _normalizeValue(val);
        }
      }
    }
    if (docId != null) {
      map['id'] = docId;
    }
    return map;
  }

  String? _questionIdAsString(Object? id) {
  if (id == null) return null;
  final s = id.toString().trim();
  return s.isEmpty ? null : s;
  }

  // ⓪ 試験の一覧（新しい年が上）
  Future<List<ExamInfo>> getExams() async => (await _bank()).exams;

  // ① すべての問題
  Future<List<Question>> getAllQuestions() async => (await _bank()).all;

  // ② 指定した年度・科目の問題一覧
  Future<List<Question>> getQuestionsByYearAndSubject(int year, String subject) async {
  final bank = await _bank();
  return bank.all.where((q) => q.year == year && q.subject == subject).toList();
  }

  // ②' 1回分の試験の問題（例: 2025r07_a）を、問題番号の順に
  Future<List<Question>> getQuestionsByExam(String examId) async {
  final bank = await _bank();
  return bank.all.where((q) => q.exam == examId).toList();
  }

  // ③ 指定した年度・科目の総問題数（これが分母になる）
  Future<int> getQuestionCount(int year, String subject) async {
  return (await getQuestionsByYearAndSubject(year, subject)).length;
  }

  // ⑤ 指定した ID の問題を、その順番で取得（復習の解き直しで使う）。もう無い問題は飛ばす
  Future<List<Question>> fetchQuestionsByIds(List<String> ids) async {
  if (ids.isEmpty) return const <Question>[];
  final bank = await _bank();
  return [
  for (final id in ids)
  if (bank.byId[id] case final question?) question,
  ];
  }

  // ⑥ 復習が必要な問題（最後に間違えた問題）と、そのとき選んだ答え
  Future<List<ReviewEntry>> fetchQuestionsToReview() async {
  final userId = _requireUserId();
  final progress = await _progress(userId)
      .where('needsReview', isEqualTo: true)
      .get();
  if (progress.docs.isEmpty) return [];

  final questions = await fetchQuestionsByIds(
  progress.docs.map((doc) => doc.id).toList(),
  );
  final questionsById = <String, Question>{
  for (final q in questions)
  if (_questionIdAsString(q.id) case final id?) id: q,
  };

  final entries = <ReviewEntry>[];
  for (final doc in progress.docs) {
  final question = questionsById[doc.id];
  final data = _asMap(doc.data());
  final wrongIndex = data['lastWrongAnswerIndex'];
  // もう無い問題や、形のおかしい記録は飛ばす
  if (question == null ||
  wrongIndex is! int ||
  wrongIndex < 0 ||
  wrongIndex >= question.choices.length) {
  continue;
  }
  entries.add(ReviewEntry(question: question, lastWrongAnswerIndex: wrongIndex));
  }
  return entries;
  }

  Future<List<QuestionHistoryEntry>> fetchQuestionHistory() async {
  final userId = _requireUserId();

  final progress = await _firestore
      .collection('users')
      .doc(userId)
      .collection('questionProgress')
      .get();

  if (progress.docs.isEmpty) return const [];

  final ids = progress.docs.map((document) => document.id).toList();
  final questions = await fetchQuestionsByIds(ids);

  final questionsById = <String, Question>{
  for (final question in questions)
  if (_questionIdAsString(question.id) case final id?) id: question,
  };

  final entries = <QuestionHistoryEntry>[];

  for (final document in progress.docs) {
  final question = questionsById[document.id];

  if (question == null) continue;

  final data = _asMap(document.data());
  final attempts = data['attempts'];
  final wrongCount = data['wrongCount'];

  if (attempts is! int ||
  wrongCount is! int ||
  attempts <= 0 ||
  wrongCount < 0 ||
  wrongCount > attempts) {
  continue;
  }

  entries.add(
  QuestionHistoryEntry(
  question: question,
  attempts: attempts,
  wrongCount: wrongCount,
  ),
  );
  }

  return entries;
  }

  // ⑥' 自分の解答の記録を全部（問題ID → 記録）。ログインしていなければ空。
  // 問題一覧の「解いた数」とホームの「今日解いた数」「続きから」で使う。
  Future<Map<String, AnswerRecord>> fetchAnswerRecords() async {
  final userId = _auth.currentUser?.uid;
  if (userId == null) return const {};
  final snapshot = await _progress(userId).get();
  final records = <String, AnswerRecord>{};
  for (final doc in snapshot.docs) {
  final data = _asMap(doc.data());
  final attempts = data['attempts'];
  final wrongCount = data['wrongCount'];
  final at = data['lastAnsweredAt'];
  final correct = data['lastAnsweredCorrectly'];
  records[doc.id] = AnswerRecord(
  questionId: doc.id,
  attempts: attempts is int ? attempts : 0,
  wrongCount: wrongCount is int ? wrongCount : 0,
  lastAnsweredAt: at is Timestamp ? at.toDate() : null,
  lastAnsweredCorrectly: correct is bool ? correct : null,
  );
  }
  return records;
  }

  // ⑦ 解答を記録する（進捗画面と復習画面がこの記録を使う）
  // users/{uid}/questionProgress/{問題ID} に、解いた回数・間違えた回数・復習が必要かを保存
  Future<void> recordAnswer(Question question, int selectedIndex) async {
  if (selectedIndex < 0 || selectedIndex >= question.choices.length) {
  throw ArgumentError.value(selectedIndex, 'selectedIndex');
  }
  final questionId = _questionIdAsString(question.id);
  if (questionId == null) {
  throw StateError('問題IDがないので、解答を記録できません');
  }
  final userId = _requireUserId();
  final isCorrect = selectedIndex == question.answerIndex;
  final record = _progress(userId).doc(questionId);

  await _firestore.runTransaction((transaction) async {
  final snapshot = await transaction.get(record);
  final previous = _asMap(snapshot.data());
  final attempts = previous['attempts'];
  final wrongCount = previous['wrongCount'];

  transaction.set(record, {
  'attempts': (attempts is int ? attempts : 0) + 1,
  'wrongCount': (wrongCount is int ? wrongCount : 0) + (isCorrect ? 0 : 1),
  'needsReview': !isCorrect,
  if (!isCorrect) 'lastWrongAnswerIndex': selectedIndex,
  'lastAnsweredCorrectly': isCorrect,
  'lastAnsweredAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
  });
  }

  CollectionReference<Map<String, dynamic>> _progress(String userId) =>
  _firestore.collection('users').doc(userId).collection('questionProgress');

  String _requireUserId() {
  final userId = _auth.currentUser?.uid;
  if (userId == null) {
  throw StateError('解答記録を保存するにはログインが必要です');
  }
  return userId;
  }
}