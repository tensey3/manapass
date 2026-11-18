import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../providers/progress_controller.dart';
import '../widgets/category_accuracy_list.dart';
import '../widgets/mock_history_tile.dart';
import '../widgets/progress_surface.dart';
import '../widgets/stat_tile.dart';
import '../widgets/weekly_time_chart.dart';

/// 進捗：全体の数字、今週の学習時間、分野別の正答率、模擬試験の記録。
/// 数字はすべて、Firestore に保存された解答記録から計算する。
/// 下に引っぱると読み込み直す。
/// The parent app shell already provides the navigation sidebar.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        return RefreshIndicator(
          onRefresh: () => ref.refresh(progressProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(wide ? 28 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('進捗', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 20),
                    ...progress.when(
                      // 読み込み直している間は、前の数字を出したままにする
                      skipLoadingOnRefresh: true,
                      loading: () => const [
                        Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
                      ],
                      error: (error, stackTrace) => [
                        _Message(
                          text: '進捗を読み込めませんでした。インターネット接続を確認してください。',
                          buttonLabel: '再読み込み',
                          onPressed: () => ref.invalidate(progressProvider),
                        ),
                      ],
                      data: (state) => state == null
                          ? [
                              _Message(
                                text: 'ログインすると、進捗が表示されます。',
                                buttonLabel: 'ログイン',
                                onPressed: () => context.go(Routes.signIn),
                              ),
                            ]
                          : _content(context, state),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _content(BuildContext context, ProgressState state) {
    final minutes = state.weekMinutes;
    return [
      if (state.questionsDone == 0) ...[
        _Message(
          text: 'まだ問題を解いていません。ランダム出題で問題を解くと、ここに記録が表示されます。',
          buttonLabel: 'ランダム出題へ',
          onPressed: () => context.push(Routes.randomQuiz),
        ),
        const SizedBox(height: 20),
      ],
      SummaryCards(state: state),
      const SizedBox(height: 26),
      const SectionTitle('今週の学習時間'),
      const SizedBox(height: 12),
      Surface(
        child: minutes == null
            ? const Text(
                '学習時間はまだ記録されていません（今後対応予定）',
                style: TextStyle(fontSize: 13, color: ProgressStyle.muted),
              )
            : WeeklyTimeChart(minutes: minutes, todayIndex: state.todayIndex),
      ),
      const SizedBox(height: 26),
      const SectionTitle('分野別の正答率'),
      const SizedBox(height: 12),
      CategoryAccuracyList(subjects: state.subjects),
      const SizedBox(height: 26),
      const SectionTitle('模擬試験の記録'),
      const SizedBox(height: 12),
      MockHistoryList(results: state.mockResults),
      const SizedBox(height: 16),
    ];
  }
}

/// 説明とボタン1つ（ログインしていない、まだ解いていない、読み込めなかった）。
class _Message extends StatelessWidget {
  const _Message({required this.text, required this.buttonLabel, required this.onPressed});

  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(backgroundColor: ProgressStyle.blue),
              child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
}
