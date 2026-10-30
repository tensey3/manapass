import 'dart:math';

import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/goal_repository.dart';

class HomeState {
  const HomeState({
    required this.examDate,
    required this.daysLeft,
    required this.answered,
    required this.target,
  });

  final DateTime examDate;
  final int daysLeft;
  final int answered;
  final int target;

  int get remaining => max(target - answered, 0);

  double get progress => target == 0 ? 0 : min(answered / target, 1.0);
}

final homeProvider = FutureProvider<HomeState>((ref) async {
  final repository = ref.watch(goalRepositoryProvider);
  final goal = await repository.fetchGoal();
  final answered = await repository.fetchTodayAnswered();
  final today = DateUtils.dateOnly(DateTime.now());
  final daysLeft = DateUtils.dateOnly(goal.examDate).difference(today).inDays;
  return HomeState(
    examDate: goal.examDate,
    daysLeft: max(daysLeft, 0),
    answered: answered,
    target: goal.dailyTarget,
  );
});
