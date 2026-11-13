import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../providers/home_controller.dart';
import '../widgets/continue_button.dart';
import '../widgets/countdown_card.dart';
import '../widgets/goal_progress_chart.dart';

/// ホーム画面（左サイドバーは app/shell 側。ここは中身だけ）。
/// 広い画面: カード2枚を横に並べる。スマホ: 縦に並べる。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _cardWidth = 220.0;
  static const _cardHeight = 230.0;
  static const _gap = 16.0;
  static const _padding = 24.0;
  // カード2枚 + すき間 = ボタンの幅（456）
  static const _rowWidth = _cardWidth * 2 + _gap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(homeProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('読み込みに失敗しました'),
                TextButton(
                  onPressed: () => ref.invalidate(homeProvider),
                  child: const Text('再読み込み'),
                ),
              ],
            ),
          ),
          data: (data) => LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= _rowWidth + _padding * 2;
              final cardWidth = wide ? _cardWidth : double.infinity;
              final countdown = CountdownCard(data: data, width: cardWidth, height: _cardHeight);
              final goal = GoalProgressChart(data: data, width: cardWidth, height: _cardHeight);
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(_padding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (wide)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [countdown, const SizedBox(width: _gap), goal],
                        )
                      else ...[
                        countdown,
                        const SizedBox(height: _gap),
                        goal,
                      ],
                      const SizedBox(height: 32),
                      ContinueButton(
                        width: wide ? _rowWidth : double.infinity,
                        onPressed: () => context.go(Routes.question),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
  }
}
