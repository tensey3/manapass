import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/question_repository.dart' hide AnswerRecord;
import '../../auth/providers/auth_controller.dart';
import 'progress_models.dart';

/// 進捗の計算に使う、保存されている記録。
class ProgressData {
  const ProgressData({required this.answers, required this.topics, this.mockResults = const []});

  final List<AnswerRecord> answers;
  final List<String> topics; // 問題にある分野すべて（まだ解いていない分野も表示するため）
  final List<MockResult> mockResults;
}

/// 分野が決まっていない問題をまとめる名前。
const otherTopic = 'その他';

/// 問題の分野。分野のない問題は、モデルが科目名（科目A など）を入れてくるので「その他」にする。
String topicOf({required String topic, required String subject}) {
  final t = topic.trim();
  return t.isEmpty || t == subject.trim() ? otherTopic : t;
}

/// 進捗の記録を読み込むところ。テストでは差し替える。
abstract interface class ProgressSource {
  /// ログインしていなければ null。
  Future<ProgressData?> load();
}

/// Firestore から読む：問題（questions）と、その人の解答記録（users/{uid}/questionProgress）。
/// 解答記録は、ランダム出題で答えたときに保存される。
class FirestoreProgressSource implements ProgressSource {
  FirestoreProgressSource(this._firestore, this._questions, this._userId);

  final FirebaseFirestore _firestore;
  final QuestionRepository _questions;
  final String? _userId;

  @override
  Future<ProgressData?> load() async {
    final userId = _userId;
    if (userId == null) return null;

    final (questions, records) = await (
      _questions.getAllQuestions(),
      _firestore.collection('users').doc(userId).collection('questionProgress').get(),
    ).wait;

    final topicById = {
      for (final q in questions)
        if (q.id != null) q.id.toString(): topicOf(topic: q.topic, subject: q.subject),
    };
    final topics = <String>[];
    for (final topic in topicById.values) {
      if (!topics.contains(topic)) topics.add(topic);
    }
    // 「その他」は最後に表示する
    if (topics.remove(otherTopic)) topics.add(otherTopic);

    // 復習画面と同じく、もう無い問題の記録は数えない
    final answers = [
      for (final doc in records.docs)
        if (topicById[doc.id] case final topic?)
          if (AnswerRecord.fromFirestore(doc.data(), topic: topic) case final record?) record,
    ];
    return ProgressData(answers: answers, topics: topics);
  }
}

final progressSourceProvider = Provider<ProgressSource>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull ?? ref.watch(firebaseAuthProvider).currentUser;
  return FirestoreProgressSource(FirebaseFirestore.instance, ref.watch(questionRepositoryProvider), user?.uid);
});
