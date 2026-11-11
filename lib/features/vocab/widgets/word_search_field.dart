import 'package:flutter/material.dart';

import 'vocab_page.dart';

/// 単語帳の検索ボックス（単語・読み・英語の意味で探せる）。
class WordSearchField extends StatelessWidget {
  const WordSearchField({super.key, required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: '検索',
        hintStyle: const TextStyle(fontSize: 16, color: VocabStyle.muted),
        prefixIcon: const Icon(Icons.search_rounded, color: VocabStyle.muted),
        filled: true,
        fillColor: VocabStyle.soft,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VocabStyle.smallRadius),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
