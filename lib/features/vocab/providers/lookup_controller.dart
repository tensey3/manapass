import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 何回調べたら英語を隠すか（設定の「英語を少しずつ減らす」）。
const hideEnglishAfter = 3;

/// それぞれの単語を、単語の詳細ページで何回調べたか。端末に保存される。
final lookupCountsProvider = AsyncNotifierProvider<LookupCounts, Map<String, int>>(LookupCounts.new);

class LookupCounts extends AsyncNotifier<Map<String, int>> {
  static const _key = 'vocab.lookups';

  late SharedPreferences _prefs;

  @override
  Future<Map<String, int>> build() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      final decoded = jsonDecode(_prefs.getString(_key) ?? '{}');
      if (decoded is Map) {
        return {
          for (final e in decoded.entries)
            if (e.key is String && e.value is int) e.key as String: e.value as int,
        };
      }
    } on FormatException {
      // 壊れていたら、最初から数え直す
    }
    return {};
  }

  /// [word] を1回調べたことにする。
  Future<void> record(String word) async {
    final current = await future;
    final next = {...current, word: (current[word] ?? 0) + 1};
    state = AsyncData(next);
    await _prefs.setString(_key, jsonEncode(next));
  }
}

/// 英語を隠すか。[reduceEnglish] は設定の「英語を少しずつ減らす」。
bool shouldHideEnglish({required bool reduceEnglish, required int lookups}) =>
    reduceEnglish && lookups >= hideEnglishAfter;
