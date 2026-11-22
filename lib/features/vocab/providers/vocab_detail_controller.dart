import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/providers/settings_controller.dart';
import '../data/vocab_data.dart';
import 'dictionary_controller.dart';
import 'wordbook_controller.dart';

/// 単語詳細ページで使う情報。出てくる問題は relatedQuestionsProvider から。
class VocabDetail {
  const VocabDetail({required this.word, required this.isSaved});

  final Word word;
  final bool isSaved; // 単語帳に入っているか
}

/// [text] の単語の詳細。辞書にない言葉なら null。
final vocabDetailProvider = Provider.family<AsyncValue<VocabDetail?>, String>((ref, text) {
  final dictionary = ref.watch(dictionaryProvider);
  final saved = ref.watch(wordbookProvider);
  if (dictionary is AsyncError) return AsyncError(dictionary.error!, dictionary.stackTrace!);
  if (saved is AsyncError) return AsyncError(saved.error!, saved.stackTrace!);
  final words = dictionary.valueOrNull;
  final texts = saved.valueOrNull;
  if (words == null || texts == null) return const AsyncLoading();
  final word = words[text];
  return AsyncData(word == null ? null : VocabDetail(word: word, isSaved: texts.contains(text)));
});

/// 単語帳で使う設定（ふりがな・英語を減らす）。読み込み中は最初の値。
final vocabSettingsProvider = Provider<SettingsState>(
  (ref) => ref.watch(settingsProvider).valueOrNull ?? const SettingsState(),
);
