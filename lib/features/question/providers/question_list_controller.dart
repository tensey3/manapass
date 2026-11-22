import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/question.dart';
import '../../../data/repositories/question_repository.dart';

/// 問題一覧のタブ（科目A / 科目B）
final selectedSubjectProvider = StateProvider<String>((ref) => '科目A');

/// アプリに入っている試験の一覧（新しい年が上）
final examsProvider = FutureProvider<List<ExamInfo>>(
  (ref) => ref.watch(questionRepositoryProvider).getExams(),
);

/// 1回分の試験の問題
final examQuestionsProvider = FutureProvider.family<List<Question>, String>(
  (ref, examId) => ref.watch(questionRepositoryProvider).getQuestionsByExam(examId),
);

/// 自分の解答の記録（問題ID → 記録）。問題を解き終わったら invalidate して読み直す。
final answerRecordsProvider = FutureProvider<Map<String, AnswerRecord>>(
  (ref) => ref.watch(questionRepositoryProvider).fetchAnswerRecords(),
);

/// その試験で、1回以上解いた問題の数
int solvedCount(String examId, Map<String, AnswerRecord> records) =>
    records.keys.where((id) => id.startsWith('${examId}_')).length;
