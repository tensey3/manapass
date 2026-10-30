import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/home_controller.dart';
import '../widgets/countdown_card.dart';
import '../widgets/goal_progress_chart.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(homeProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              const Center(child: Text('読み込みに失敗しました')),
          data: (state) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: [
                      CountdownCard(state: state),
                      GoalProgressChart(state: state),
                    ],
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: '続きから',
                    onPressed: () => context.go(Routes.question),
                  ),
                ],
              ),
            ),
          ),
        );
  }
}
