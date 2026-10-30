import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/exam_goal.dart';

abstract interface class GoalRepository {
  Future<ExamGoal> fetchGoal();
  Future<int> fetchTodayAnswered();
}

class InMemoryGoalRepository implements GoalRepository {
  @override
  Future<ExamGoal> fetchGoal() async => ExamGoal(
        examDate: DateTime.now().add(const Duration(days: 42)),
        dailyTarget: 10,
      );

  @override
  Future<int> fetchTodayAnswered() async => 5;
}

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => InMemoryGoalRepository(),
);
