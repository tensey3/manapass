import 'package:flutter/material.dart';

import '../data/vocab_data.dart';
import 'vocab_page.dart';

/// 意味をどこから持ってきたかを表示する（どのくらい信用できるか分かるように）。
class WordLabelChip extends StatelessWidget {
  const WordLabelChip({super.key, required this.label});

  final WordLabel label;

  @override
  Widget build(BuildContext context) {
    final (text, color, textColor, icon) = switch (label) {
      WordLabel.checked => ('確認済み', VocabStyle.correct, VocabStyle.correctText, Icons.verified_rounded),
      WordLabel.general => ('一般的な意味', VocabStyle.primary, VocabStyle.primaryText, Icons.info_rounded),
      WordLabel.auto => ('自動翻訳・誤りの可能性あり', VocabStyle.warning, VocabStyle.warningText, Icons.translate_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: textColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: textColor)),
          ),
        ],
      ),
    );
  }
}
