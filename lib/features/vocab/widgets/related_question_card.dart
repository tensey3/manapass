import 'package:flutter/material.dart';

import '../../../data/models/question.dart';
import '../providers/related_questions_controller.dart';
import 'vocab_page.dart';

/// 単語が出てくる問題の1枚：出典と問題文（2行まで）。
/// 押すと、問題文の全部と選択肢を開く（もう一度押すと閉じる）。
class RelatedQuestionCard extends StatefulWidget {
  const RelatedQuestionCard({super.key, required this.question, required this.word});

  final Question question;
  final String word; // 太字にする単語

  @override
  State<RelatedQuestionCard> createState() => _RelatedQuestionCardState();
}

class _RelatedQuestionCardState extends State<RelatedQuestionCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return Semantics(
      button: true,
      expanded: _open,
      child: VocabCard(
        onTap: () => setState(() => _open = !_open),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    questionSourceLabel(q),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: VocabStyle.muted),
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: VocabStyle.muted,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text.rich(
              _highlight(q.question, widget.word, const TextStyle(fontSize: 14)),
              maxLines: _open ? null : 2,
              overflow: _open ? null : TextOverflow.ellipsis,
            ),
            if (_open) ...[
              const SizedBox(height: 10),
              for (final choice in q.choices)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text.rich(
                    _highlight(choice, widget.word, const TextStyle(fontSize: 14, color: VocabStyle.ink)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// [text] の中の [word] を太字・色つきにする。
TextSpan _highlight(String text, String word, TextStyle style) {
  if (word.isEmpty || !text.contains(word)) return TextSpan(text: text, style: style);
  final parts = text.split(word);
  return TextSpan(
    style: style,
    children: [
      for (var i = 0; i < parts.length; i++) ...[
        if (i > 0)
          TextSpan(
            text: word,
            style: const TextStyle(fontWeight: FontWeight.w900, color: VocabStyle.primaryText),
          ),
        TextSpan(text: parts[i]),
      ],
    ],
  );
}
