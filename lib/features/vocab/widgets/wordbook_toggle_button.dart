import 'package:flutter/material.dart';

import 'vocab_page.dart';

/// 「単語帳に追加」/「単語帳から外す」ボタン。
class WordbookToggleButton extends StatelessWidget {
  const WordbookToggleButton({super.key, required this.isSaved, required this.onPressed});

  final bool isSaved;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isSaved) {
      return VocabOutlinedButton(label: '単語帳から外す', icon: Icons.bookmark_remove_rounded, onPressed: onPressed);
    }
    return VocabFilledButton(label: '単語帳に追加', icon: Icons.bookmark_add_rounded, onPressed: onPressed);
  }
}
