import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/goal_repository.dart';
import '../../../data/repositories/question_repository.dart';
import 'home_data_source.dart';

/// 設定画面（試験日と目標）で保存した値を読む HomeDataSource。
class GoalHomeDataSource implements HomeDataSource {
  const GoalHomeDataSource(this._goals, this._questions);

  final GoalRepository _goals;
  final QuestionRepository _questions;

  @override
  Future<HomeData> load() async {
    final goal = await _goals.fetchGoal();
    final answered = await _goals.fetchTodayAnswered();
    final totalCount = await _questions.getQuestionCount(2026, '科目A');
    return HomeData(
      examDate: goal.examDate,
      todayAnswered: answered,
      dailyGoal: goal.dailyTarget,
      totalQuestions: totalCount,
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

/// ホーム画面のデータ。設定画面で保存すると読み直される。
final homeProvider = FutureProvider<HomeData>(
  (ref) => ref.watch(homeDataSourceProvider).load(),
);
