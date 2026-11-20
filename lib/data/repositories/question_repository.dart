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

  Question _questionFromDoc(DocumentSnapshot<Object?> doc) {
  return Question.fromMap(_asMap(doc.data(), docId: doc.id));
  }

  String? _questionIdAsString(Object? id) {
  if (id == null) return null;
  final s = id.toString().trim();
  return s.isEmpty ? null : s;
  }

  // ① Firestore の 'questions' コレクションからすべての問題を取得
  Future<List<Question>> getAllQuestions() async {
  try {
  final snapshot = await _firestore.collection('questions').get();
  return snapshot.docs.map(_questionFromDoc).toList();
  } catch (e) {
  print('Firestore fetch error: $e');
  return [];
  }
  }

  // ② 指定した年度・科目の問題一覧を取得
  Future<List<Question>> getQuestionsByYearAndSubject(int year, String subject) async {
  try {
  final querySnapshot = await _firestore
      .collection('questions')
      .where('year', isEqualTo: year)
      .where('subject', isEqualTo: subject)
      .get();

  return querySnapshot.docs.map(_questionFromDoc).toList();
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
  final safeIds = List<String>.from(ids);
  if (safeIds.isEmpty) return const <Question>[];

  final questionsById = <String, Question>{};
  // Firestore の whereIn は一度に30件まで
  for (var start = 0; start < safeIds.length; start += 30) {
  final batch = List<String>.from(safeIds.skip(start).take(30));
  final snapshot = await _firestore
      .collection('questions')
      .where(FieldPath.documentId, whereIn: batch)
      .get();
  for (final doc in snapshot.docs) {
  questionsById[doc.id] = _questionFromDoc(doc);
  }
  }

  final result = <Question>[];
  for (final id in safeIds) {
  final question = questionsById[id];
  if (question != null) {
  result.add(question);
  }
  }
  return result;
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