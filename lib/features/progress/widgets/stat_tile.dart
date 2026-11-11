import 'package:flutter/material.dart';

import '../providers/progress_controller.dart';
import 'progress_surface.dart';

/// 上の4つの数字：正答率、今週の学習時間、解いた問題、復習が必要。
/// 狭い画面では2列、広い画面では4列。
class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.state});

  final ProgressState state;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      StatTile(value: '${state.accuracyPercent}%', label: '正答率'),
      StatTile(value: formatMinutes(state.weekTotalMinutes), label: '今週の学習時間'),
      StatTile(value: '${state.questionsDone}', label: '解いた問題'),
      StatTile(value: '${state.toReview}', label: '復習が必要'),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth < 520 ? 2 : 4;
      final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [for (final tile in tiles) SizedBox(width: width, child: tile)],
      );
    });
  }
}

/// 数字1つと、その説明。
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Surface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: ProgressStyle.muted, fontSize: 11)),
        ],
      ),
    );
  }
}
