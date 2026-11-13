import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_controller.dart';
import '../models/question.dart';

class QuestionReviewEntry {
  const QuestionReviewEntry({
    required this.question,
    required this.lastWrongAnswerIndex,
  });

  final Question question;
  final int lastWrongAnswerIndex;
}

class QuestionRepository {
  QuestionRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _questions =>
      _firestore.collection('questions');

  Future<List<Question>> fetchQuestions() async {
    final snapshot = await _questions.get();
    return snapshot.docs
        .map((document) => Question.fromFirestore(document.id, document.data()))
        .toList(growable: false);
  }

  Future<List<Question>> fetchQuestionsByIds(List<String> ids) async {
    final questionsById = <String, Question>{};
    for (var start = 0; start < ids.length; start += 30) {
      final batch = ids.skip(start).take(30).toList(growable: false);
      if (batch.isEmpty) continue;

      final snapshot = await _questions
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final document in snapshot.docs) {
        questionsById[document.id] = Question.fromFirestore(
          document.id,
          document.data(),
        );
      }
    }
    return [
      for (final id in ids)
        if (questionsById[id] case final question?) question,
    ];
  }

  Future<List<QuestionReviewEntry>> fetchQuestionsToReview() async {
    final userId = _requireUserId();
    final progress = await _firestore
        .collection('users')
        .doc(userId)
        .collection('questionProgress')
        .where('needsReview', isEqualTo: true)
        .get();
    if (progress.docs.isEmpty) return const [];

    final ids = progress.docs.map((document) => document.id).toList();
    final questions = await fetchQuestionsByIds(ids);
    final questionsById = {
      for (final question in questions) question.id: question,
    };

    final entries = <QuestionReviewEntry>[];
    for (final document in progress.docs) {
      final question = questionsById[document.id];
      if (question == null) continue;

      final answerIndex = document.data()['lastWrongAnswerIndex'];
      if (answerIndex is! int ||
          answerIndex < 0 ||
          answerIndex >= question.choices.length) {
        throw FormatException(
          'users/$userId/questionProgress/${document.id} の '
          'lastWrongAnswerIndex が不正です',
        );
      }
      entries.add(
        QuestionReviewEntry(
          question: question,
          lastWrongAnswerIndex: answerIndex,
        ),
      );
    }
    return entries;
  }

  Future<void> recordAnswer(Question question, int selectedIndex) async {
    if (selectedIndex < 0 || selectedIndex >= question.choices.length) {
      throw ArgumentError.value(selectedIndex, 'selectedIndex');
    }
    final userId = _requireUserId();
    final isCorrect = selectedIndex == question.answerIndex;
    final progress = _firestore
        .collection('users')
        .doc(userId)
        .collection('questionProgress')
        .doc(question.id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(progress);
      final previous = snapshot.data() ?? const <String, dynamic>{};
      final attempts = previous['attempts'];
      final wrongCount = previous['wrongCount'];

      transaction.set(progress, {
        'attempts': (attempts is int ? attempts : 0) + 1,
        'wrongCount':
            (wrongCount is int ? wrongCount : 0) + (isCorrect ? 0 : 1),
        'needsReview': !isCorrect,
        if (!isCorrect) 'lastWrongAnswerIndex': selectedIndex,
        'lastAnsweredCorrectly': isCorrect,
        'lastAnsweredAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  String _requireUserId() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw StateError('解答記録を保存するにはログインが必要です');
    }
    return userId;
  }
}

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository(
    FirebaseFirestore.instance,
    ref.watch(firebaseAuthProvider),
  );
});
