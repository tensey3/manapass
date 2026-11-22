import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vocab_data.dart';

/// 調べられる全部の単語：チームの用語集（確認済み）+ 問題に出てくる単語の一般の辞書（JMdict）。
/// 同じ言葉が両方にあるときは、用語集の意味を使う。
/// 辞書のファイル（assets/dict/words.json）は tool/questions/add_furigana.py で作る。
final dictionaryProvider = FutureProvider<Map<String, Word>>((ref) async {
  final words = <String, Word>{};
  try {
    final raw = jsonDecode(await rootBundle.loadString('assets/dict/words.json')) as Map<String, dynamic>;
    for (final e in raw.entries) {
      final v = e.value as Map<String, dynamic>;
      words[e.key] = Word(
        text: e.key,
        reading: v['reading'] as String?,
        meaning: v['meaning'] as String? ?? '',
        label: WordLabel.general,
      );
    }
  } catch (_) {
    // 辞書が読めなくても、用語集だけで使えるようにする
  }
  words.addAll(glossary);
  return words;
});
