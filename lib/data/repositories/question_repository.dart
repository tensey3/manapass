import 'package:cloud_firestore/cloud_firestore.dart';
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

class QuestionRepository {
  final FirebaseFirestore _firestore;

  QuestionRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

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

  // 復習用の間違えた問題リストを取得（プレースホルダー）
  Future<List<ReviewEntry>> fetchQuestionsToReview() async {
    return [];
  }

  // ④ 問題データを Firestore に新規追加するメソッド
  Future<void> insertQuestion(Question question) async {
    await _firestore.collection('questions').add(question.toMap());
  }
}