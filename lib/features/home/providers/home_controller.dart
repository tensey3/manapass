import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/goal_repository.dart';
import '../../../data/repositories/question_repository.dart';
import 'home_data_source.dart';

/// 設定画面（試験日と目標）で保存した値と、自分の解答の記録を読む HomeDataSource。
class GoalHomeDataSource implements HomeDataSource {
  const GoalHomeDataSource(this._goals, this._questions);

  final GoalRepository _goals;
  final QuestionRepository _questions;

  @override
  Future<HomeData> load() async {
    final goal = await _goals.fetchGoal();
    // 解答の記録が読めなくても（通信エラーなど）、ホームは出す
    Map<String, AnswerRecord> records;
    try {
      records = await _questions.fetchAnswerRecords();
    } catch (_) {
      records = const {};
    }
    final now = DateTime.now();
    bool isToday(DateTime? t) => t != null && t.year == now.year && t.month == now.month && t.day == now.day;

    // 今日解いた問題の数（同じ問題を何回解いても1問）
    final answeredToday = records.values.where((r) => isToday(r.lastAnsweredAt?.toLocal())).length;

    // 最後に解いた問題
    AnswerRecord? last;
    for (final r in records.values) {
      final at = r.lastAnsweredAt;
      if (at != null && (last == null || at.isAfter(last.lastAnsweredAt!))) last = r;
    }

    return HomeData(
      examDate: goal.examDate,
      todayAnswered: answeredToday,
      dailyGoal: goal.dailyTarget,
      lastQuestionId: last?.questionId,
    );
  }
}

/// 画面確認だけしたいときは DemoHomeDataSource() に変えられる。
final homeDataSourceProvider = Provider<HomeDataSource>(
  (ref) => GoalHomeDataSource(
    ref.watch(goalRepositoryProvider),
    ref.watch(questionRepositoryProvider),
  ),
);

/// ホーム画面のデータ。設定画面で保存したり、問題を解いたりすると読み直される。
final homeProvider = FutureProvider<HomeData>(
  (ref) => ref.watch(homeDataSourceProvider).load(),
);
