import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/question.dart';
import '../../../data/repositories/question_repository.dart';
import '../../auth/providers/auth_controller.dart';

/// Firestore の問題すべて。単語の「出てくる問題」を探すのに使う。
/// 一度読み込んだら使い回す（ログインする人が変わったら読み込み直す）。
final vocabQuestionsProvider = FutureProvider<List<Question>>((ref) {
  ref.watch(authStateProvider.select((user) => user.valueOrNull?.uid));
  return ref.watch(questionRepositoryProvider).getAllQuestions();
});

/// [word] が問題文か選択肢に出てくる問題。新しい年度から順に。
List<Question> questionsContaining(List<Question> questions, String word) {
  if (word.trim().isEmpty) return const [];
  final found = [
    for (final q in questions)
      if (q.question.contains(word) || q.choices.any((c) => c.contains(word))) q,
  ];
  found.sort((a, b) {
    final byYear = (b.year ?? 0).compareTo(a.year ?? 0);
    return byYear != 0 ? byYear : '${a.id}'.compareTo('${b.id}');
  });
  return found;
}

/// [word] が出てくる問題（読み込み中・失敗も含めて）。
final relatedQuestionsProvider = Provider.family<AsyncValue<List<Question>>, String>((ref, word) {
  return ref.watch(vocabQuestionsProvider).whenData((questions) => questionsContaining(questions, word));
});

/// 問題の出典の表示（例：2025年度・科目A・問3）。
/// 問の番号は id の最後の数字（例：2025_a_q03 → 3）から取る。
String questionSourceLabel(Question q) {
  final number = RegExp(r'q(\d+)$').firstMatch('${q.id}')?.group(1);
  final topic = q.topic.trim();
  return [
    if (q.year != null) '${q.year}年度',
    if (q.subject.trim().isNotEmpty) q.subject.trim(),
    if (number != null) '問${int.parse(number)}',
    if (topic.isNotEmpty && topic != q.subject.trim()) topic,
  ].join('・');
}
