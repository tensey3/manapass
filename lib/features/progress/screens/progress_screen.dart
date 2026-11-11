import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/progress_controller.dart';
import '../widgets/category_accuracy_list.dart';
import '../widgets/mock_history_tile.dart';
import '../widgets/progress_surface.dart';
import '../widgets/stat_tile.dart';
import '../widgets/weekly_time_chart.dart';

/// 進捗：全体の数字、今週の学習時間、分野別の正答率、模擬試験の記録。
/// 数字はすべて記録から計算する（今は見本のデータ）。
/// The parent app shell already provides the navigation sidebar.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        return SingleChildScrollView(
          padding: EdgeInsets.all(wide ? 28 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('進捗', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  SummaryCards(state: state),
                  const SizedBox(height: 26),
                  const SectionTitle('今週の学習時間'),
                  const SizedBox(height: 12),
                  Surface(child: WeeklyTimeChart(minutes: state.weekMinutes, todayIndex: state.todayIndex)),
                  const SizedBox(height: 26),
                  const SectionTitle('分野別の正答率'),
                  const SizedBox(height: 12),
                  CategoryAccuracyList(subjects: state.subjects),
                  const SizedBox(height: 26),
                  const SectionTitle('模擬試験の記録'),
                  const SizedBox(height: 12),
                  MockHistoryList(results: state.mockResults),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
