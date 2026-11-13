import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

import '../providers/review_data_source.dart';

/// 苦手分野カード（分野名・正答率バー）。
class WeakAreaCard extends StatelessWidget {
  final WeakArea area;
  const WeakAreaCard({super.key, required this.area});

  @override
  Widget build(BuildContext context) {
    final pct = (area.accuracy * 100).round();
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(area.category, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: area.accuracy,
            minHeight: 6,
            color: const Color(0xFFFF9500),
            backgroundColor: AppColors.track,
          ),
        ),
        const SizedBox(height: 6),
        Text('正答率 $pct%（${area.correct}/${area.total}）',
            style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ]),
    );
  }
}
