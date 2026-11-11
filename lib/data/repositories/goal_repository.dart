import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exam_goal.dart';

abstract interface class GoalRepository {
  Future<ExamGoal> fetchGoal();
  Future<void> saveGoal(ExamGoal goal);
  Future<int> fetchTodayAnswered();
}

class InMemoryGoalRepository implements GoalRepository {
  // 設定画面（試験日と目標）で保存した値。端末に保存される。
  static const _examDateKey = 'goal.examDate';
  static const _dailyTargetKey = 'goal.dailyTarget';

  @override
  Future<ExamGoal> fetchGoal() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
    } catch (_) {
      // 保存場所が使えないとき（テストなど）は、最初の値を使う
    }
    final savedDate = DateTime.tryParse(prefs?.getString(_examDateKey) ?? '');
    return ExamGoal(
      examDate: savedDate ?? DateTime.now().add(const Duration(days: 42)),
      dailyTarget: prefs?.getInt(_dailyTargetKey) ?? 10,
    );
  }

  @override
  Future<void> saveGoal(ExamGoal goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_examDateKey, goal.examDate.toIso8601String());
    await prefs.setInt(_dailyTargetKey, goal.dailyTarget);
  }

  @override
  Future<int> fetchTodayAnswered() async => 5;
}

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => InMemoryGoalRepository(),
);
