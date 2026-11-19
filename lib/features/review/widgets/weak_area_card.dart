import 'package:flutter/material.dart';

import '../providers/review_data_source.dart';

/// 苦手分野カード（設計書 No.12〜20）：分野名・進捗バー(正答率)・%・「>」
class WeakAreaCard extends StatelessWidget {
  const WeakAreaCard({
    super.key,
    required this.area,
    this.onTap,
    this.selected = false,
  });

  final WeakArea area;
  final VoidCallback? onTap;

  /// 絞り込み中の分野かどうか
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final percent = (area.accuracy.clamp(0.0, 1.0) * 100).round();
    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: selected
            ? const BorderSide(color: Color(0xFF3B9EFF), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  area.category,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: area.accuracy.clamp(0.0, 1.0),
                    minHeight: 10,
                    color: const Color(0xFFF08C00),
                    backgroundColor: const Color(0xFFEDF1F6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 40,
                child: Text('$percent%',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
