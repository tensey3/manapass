import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/question.dart';
import '../../../data/repositories/question_repository.dart';

// リポジトリのプロバイダー
final questionRepositoryProvider = Provider((ref) => QuestionRepository());

// 現在選択されているタブ（例: '科目A' または '科目B'）を管理する Provider
final selectedSubjectProvider = StateProvider<String>((ref) => '科目A');

// ==========================================
// 追加・拡張部分
// ==========================================

// 1. 指定した年度と科目に対応する問題リストを非同期で取得する Provider (Family)
// 例: ref.watch(questionsProvider((year: 2026, subject: '科目A'))) のように呼び出せます
final questionsProvider = FutureProvider.family<List<Question>, ({int year, String subject})>((ref, arg) async {
  final repository = ref.watch(questionRepositoryProvider);
  return await repository.getQuestionsByYearAndSubject(arg.year, arg.subject);
});

// 2. 指定した年度・科目の総問題数を取得する Provider
final questionCountProvider = FutureProvider.family<int, ({int year, String subject})>((ref, arg) async {
  final repository = ref.watch(questionRepositoryProvider);
  return await repository.getQuestionCount(arg.year, arg.subject);
});

// 3. （オプション）ユーザーの解答進捗（例: 「何問中何問正解したか」や「完了したか」）を管理するステートやプロバイダー
// 必要に応じて AnswerRepository などをここに組み込んでいきます