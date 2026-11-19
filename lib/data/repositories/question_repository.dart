import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';

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
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  QuestionRepository([FirebaseFirestore? firestore, FirebaseAuth? auth])
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ① Firestore の 'questions' コレクションからすべての問題を取得
  Future<List<Question>> getAllQuestions() async {
    try {
      final snapshot = await _firestore.collection('questions').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Question.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Firestore fetch error: $e');
      return [];
    }
  }

  // ② 指定した年度・科目の問題一覧を取得
  Future<List<Question>> getQuestionsByYearAndSubject(int year, String subject) async {
    try {
      // Firestore側で効率よく絞り込むクエリ
      final querySnapshot = await _firestore
          .collection('questions')
          .where('year', isEqualTo: year)
          .where('subject', isEqualTo: subject)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Question.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      return [];
    }
  }

  // ③ 指定した年度・科目の総問題数を取得（これが分母になります）
  Future<int> getQuestionCount(int year, String subject) async {
    try {
      final questions = await getQuestionsByYearAndSubject(year, subject);
      return questions.length;
    } catch (e) {
      print('Firestore count error: $e');
      return 0;
    }
  }

  // ⑤ 指定した ID の問題を、その順番で取得（復習の解き直しで使う）
  Future<List<Question>> fetchQuestionsByIds(List<String> ids) async {
    final questionsById = <String, Question>{};
    // Firestore の whereIn は一度に30件まで
    for (var start = 0; start < ids.length; start += 30) {
      final batch = ids.skip(start).take(30).toList();
      final snapshot = await _firestore
          .collection('questions')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final doc in snapshot.docs) {
        questionsById[doc.id] = Question.fromMap({...doc.data(), 'id': doc.id});
      }
    }
    return [
      for (final id in ids)
        if (questionsById[id] case final question?) question,
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
    final questionsById = {for (final q in questions) q.id.toString(): q};

    final entries = <ReviewEntry>[];
    for (final doc in progress.docs) {
      final question = questionsById[doc.id];
      final wrongIndex = doc.data()['lastWrongAnswerIndex'];
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

    final questionsById = {
      for (final question in questions) question.id: question,
    };

    final entries = <QuestionHistoryEntry>[];

    for (final document in progress.docs) {
      final question = questionsById[document.id];

      if (question == null) continue;

      final data = document.data();
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

  // ⑦ 解答を記録する（進捗画面と復習画面がこの記録を使う）
  // users/{uid}/questionProgress/{問題ID} に、解いた回数・間違えた回数・復習が必要かを保存
  Future<void> recordAnswer(Question question, int selectedIndex) async {
    if (selectedIndex < 0 || selectedIndex >= question.choices.length) {
      throw ArgumentError.value(selectedIndex, 'selectedIndex');
    }
    final questionId = question.id?.toString();
    if (questionId == null || questionId.isEmpty) {
      throw StateError('問題IDがないので、解答を記録できません');
    }
    final userId = _requireUserId();
    final isCorrect = selectedIndex == question.answerIndex;
    final record = _progress(userId).doc(questionId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(record);
      final rawPrevious = snapshot.data();
      final previous = rawPrevious is Map<String, dynamic>
          ? rawPrevious
          : const <String, dynamic>{};
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

  _progress(String userId) =>
      _firestore.collection('users').doc(userId).collection('questionProgress');

  String _requireUserId() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw StateError('解答記録を保存するにはログインが必要です');
    }
    return userId;
  }

  // ④ 問題データを Firestore に新規追加するメソッド
  Future<void> insertQuestion(Question question) async {
    await _firestore.collection('questions').add(question.toMap());
  }
}