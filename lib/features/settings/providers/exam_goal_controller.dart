import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/exam_goal.dart';
import '../../../data/repositories/goal_repository.dart';
import '../../home/providers/home_controller.dart';

/// 試験日と1日の目標。ホーム画面と同じデータを使う。
final examGoalProvider = FutureProvider<ExamGoal>(
  (ref) => ref.watch(goalRepositoryProvider).fetchGoal(),
);

/// 保存して、設定画面とホーム画面の表示を新しくする。
Future<void> saveExamGoal(WidgetRef ref, ExamGoal goal) async {
  await ref.read(goalRepositoryProvider).saveGoal(goal);
  ref.invalidate(examGoalProvider);
  ref.invalidate(homeProvider);
}
