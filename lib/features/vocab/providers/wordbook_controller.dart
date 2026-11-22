import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/vocab_data.dart';
import 'dictionary_controller.dart';

/// 単語帳に入っている単語（追加した順）。端末に保存されるので、アプリを閉じても残る。
final wordbookProvider = AsyncNotifierProvider<WordbookController, List<String>>(WordbookController.new);

class WordbookController extends AsyncNotifier<List<String>> {
  static const _key = 'vocab.savedWords';

  late SharedPreferences _prefs;

  @override
  Future<List<String>> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getStringList(_key) ?? initialSavedWords;
  }

  /// 入っていれば外し、入っていなければ追加する。
  Future<void> toggle(String word) async {
    final current = await future;
    final next = current.contains(word) ? current.where((w) => w != word).toList() : [...current, word];
    state = AsyncData(next);
    await _prefs.setStringList(_key, next);
  }
}

/// 単語帳の単語を、辞書（用語集 + 一般の辞書）の情報つきで。
final savedWordsProvider = Provider<AsyncValue<List<Word>>>((ref) {
  final dictionary = ref.watch(dictionaryProvider);
  final saved = ref.watch(wordbookProvider);
  if (dictionary is AsyncError) return AsyncError(dictionary.error!, dictionary.stackTrace!);
  if (saved is AsyncError) return AsyncError(saved.error!, saved.stackTrace!);
  final words = dictionary.valueOrNull;
  final texts = saved.valueOrNull;
  if (words == null || texts == null) return const AsyncLoading();
  return AsyncData([
    for (final t in texts)
      if (words[t] != null) words[t]!,
  ]);
});
