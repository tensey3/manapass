import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/progress_sample.dart';

/// 分野ごとの正答率。まだ解いていない分野は percent が null。
class SubjectAccuracy {
  const SubjectAccuracy(this.name, this.percent);

  final String name;
  final int? percent;
}

/// 進捗画面に表示するもの。すべて記録から計算する。
class ProgressState {
  const ProgressState({
    required this.accuracyPercent,
    required this.weekMinutes,
    required this.todayIndex,
    required this.questionsDone,
    required this.toReview,
    required this.subjects,
    required this.mockResults,
  });

  final int accuracyPercent; // 全体の正答率
  final List<int?> weekMinutes; // 月〜日の学習時間（分）。今日より後の日は null
  final int todayIndex; // 0 = 月曜日
  final int questionsDone; // 解いた問題の数
  final int toReview; // 最後に間違えた問題の数（復習が必要）
  final List<SubjectAccuracy> subjects;
  final List<MockResult> mockResults; // 新しい順

  int get weekTotalMinutes => weekMinutes.whereType<int>().fold(0, (a, b) => a + b);
}

/// [now] を変えると、その日から見た進捗になる（テスト用）。
ProgressState buildProgress({
  required List<AnswerRecord> answers,
  required List<int> studyMinutes,
  required List<MockResult> mockResults,
  required DateTime now,
}) {
  final attempts = answers.fold(0, (sum, a) => sum + a.attempts);
  final correct = answers.fold(0, (sum, a) => sum + a.correct);
  final todayIndex = now.weekday - 1;

  SubjectAccuracy subject(String name) {
    final rows = answers.where((a) => a.topic == name);
    final tries = rows.fold(0, (sum, a) => sum + a.attempts);
    final right = rows.fold(0, (sum, a) => sum + a.correct);
    return SubjectAccuracy(name, tries == 0 ? null : (right * 100 / tries).round());
  }

  return ProgressState(
    accuracyPercent: attempts == 0 ? 0 : (correct * 100 / attempts).round(),
    weekMinutes: [for (var i = 0; i < 7; i++) i <= todayIndex ? studyMinutes[i] : null],
    todayIndex: todayIndex,
    questionsDone: answers.length,
    toReview: answers.where((a) => !a.lastCorrect).length,
    subjects: [for (final name in progressSubjects) subject(name)],
    mockResults: [...mockResults]..sort((a, b) => b.date.compareTo(a.date)),
  );
}

final progressProvider = Provider<ProgressState>(
  (ref) => buildProgress(
    answers: sampleAnswers,
    studyMinutes: sampleStudyMinutes,
    mockResults: sampleMockResults,
    now: DateTime.now(),
  ),
);
