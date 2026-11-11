import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vocab_data.dart';
import 'wordbook_controller.dart';

/// 単語詳細ページで使う情報。
class VocabDetail {
  const VocabDetail({required this.word, required this.isSaved, required this.questions});

  final Word word;
  final bool isSaved; // 単語帳に入っているか
  final List<SampleQuestion> questions; // この単語が出てくる問題
}

/// [text] の単語の詳細。用語集にない言葉なら null。
final vocabDetailProvider = Provider.family<AsyncValue<VocabDetail?>, String>((ref, text) {
  final word = glossary[text];
  return ref.watch(wordbookProvider).whenData(
        (saved) => word == null
            ? null
            : VocabDetail(word: word, isSaved: saved.contains(text), questions: questionsWith(text)),
      );
});
