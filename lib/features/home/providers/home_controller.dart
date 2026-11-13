import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/goal_repository.dart';
import 'home_data_source.dart';

/// 設定画面（試験日と目標）で保存した値を読む HomeDataSource。
class GoalHomeDataSource implements HomeDataSource {
  const GoalHomeDataSource(this._goals);

  final GoalRepository _goals;

  @override
  Future<HomeData> load() async {
    final goal = await _goals.fetchGoal();
    final answered = await _goals.fetchTodayAnswered();
    return HomeData(
      examDate: goal.examDate,
      todayAnswered: answered,
      dailyGoal: goal.dailyTarget,
    );
  }
}

/// 画面確認だけしたいときは DemoHomeDataSource() に変えられる。
final homeDataSourceProvider = Provider<HomeDataSource>(
  (ref) => GoalHomeDataSource(ref.watch(goalRepositoryProvider)),
);

/// ホーム画面のデータ。設定画面で保存すると読み直される。
final homeProvider = FutureProvider<HomeData>(
  (ref) => ref.watch(homeDataSourceProvider).load(),
);
