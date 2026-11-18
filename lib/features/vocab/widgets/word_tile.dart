import 'package:flutter/material.dart';

import '../data/vocab_data.dart';
import 'vocab_page.dart';

/// 単語帳の一覧の1行：左に単語と読み、右に英語の意味。
/// [showReading] = 設定でふりがなを表示するか。[hideMeaning] = 3回調べたので英語を隠すか。
class WordTile extends StatelessWidget {
  const WordTile({
    super.key,
    required this.word,
    required this.onTap,
    this.showReading = true,
    this.hideMeaning = false,
  });

  final Word word;
  final VoidCallback onTap;
  final bool showReading;
  final bool hideMeaning;

  @override
  Widget build(BuildContext context) {
    return VocabCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(word.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                if (showReading && word.reading != null)
                  Text(
                    word.reading!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VocabStyle.muted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: hideMeaning
                ? const Text(
                    '英語は隠しています',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VocabStyle.muted),
                  )
                : Text(
                    word.meaning,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
          ),
          const Icon(Icons.chevron_right_rounded, color: VocabStyle.muted),
        ],
      ),
    );
  }
}
