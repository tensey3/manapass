import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/home_data_source.dart';
import 'home_card.dart';

/// 「試験まで あと ○日」と試験日を表示するカード。
class CountdownCard extends StatelessWidget {
  const CountdownCard({super.key, required this.data, this.width = 220, this.height});

  final HomeData data;
  final double width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.labelMedium?.copyWith(
      color: AppColors.textMuted,
      fontWeight: FontWeight.w700,
    );
    final examDate = data.examDate;
    return HomeCard(
      width: width,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (data.examName != null)
            Text(data.examName!, style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            '試験まで あと',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                data.daysLeft?.toString() ?? '--',
                style: textTheme.displayLarge?.copyWith(
                  color: AppColors.primary,
                  fontSize: 72,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '日',
                style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          Text(
            examDate == null ? '試験日を設定してください' : DateFormat('M月d日(E)', 'ja').format(examDate),
            style: muted,
          ),
        ],
      ),
    );
  }
}
