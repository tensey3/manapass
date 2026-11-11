import 'package:flutter/material.dart';

import '../data/vocab_data.dart';
import 'vocab_page.dart';

/// 単語が出てくる問題の1枚：出典と問題文（2行まで）。
/// 問題画面ができたら、押して問題を開けるようにする。
class RelatedQuestionCard extends StatelessWidget {
  const RelatedQuestionCard({super.key, required this.question});

  final SampleQuestion question;

  @override
  Widget build(BuildContext context) {
    return VocabCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${question.source}・${question.topic}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: VocabStyle.muted),
          ),
          const SizedBox(height: 2),
          Text(
            question.plainBody,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
