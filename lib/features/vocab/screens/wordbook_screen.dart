import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/vocab_data.dart';
import '../providers/dictionary_controller.dart';
import '../providers/lookup_controller.dart';
import '../providers/vocab_detail_controller.dart';
import '../providers/wordbook_controller.dart';
import '../vocab_routes.dart';
import '../widgets/vocab_page.dart';
import '../widgets/word_search_field.dart';
import '../widgets/word_tile.dart';

/// [query] に合う単語か（単語・読み・英語の意味で探す）。
bool wordMatches(Word w, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return w.text.toLowerCase().contains(q) || (w.reading?.contains(q) ?? false) || w.meaning.toLowerCase().contains(q);
}

/// 単語帳：保存した単語の一覧、検索、復習（カード）を始めるボタン。
/// 検索すると、単語帳にない用語集の単語も出てくる（押すと詳細ページで追加できる）。
class WordbookScreen extends ConsumerStatefulWidget {
  const WordbookScreen({super.key});

  @override
  ConsumerState<WordbookScreen> createState() => _WordbookScreenState();
}

class _WordbookScreenState extends ConsumerState<WordbookScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(vocabSettingsProvider);
    final lookups = ref.watch(lookupCountsProvider).valueOrNull ?? const {};

    Widget tile(Word w) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: WordTile(
            word: w,
            showReading: settings.furigana,
            hideMeaning: shouldHideEnglish(reduceEnglish: settings.reduceEnglish, lookups: lookups[w.text] ?? 0),
            onTap: () => context.push(VocabRoutes.word(w.text)),
          ),
        );

    return ref.watch(savedWordsProvider).when(
          loading: () => const VocabPage(
            title: '単語帳',
            showBack: false,
            children: [Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))],
          ),
          error: (error, stackTrace) => const VocabPage(
            title: '単語帳',
            showBack: false,
            children: [Padding(padding: EdgeInsets.all(40), child: Center(child: Text('読み込みに失敗しました')))],
          ),
          data: (all) {
            final searching = _query.trim().isNotEmpty;
            final saved = all.where((w) => wordMatches(w, _query)).toList();
            final savedTexts = {for (final w in all) w.text};
            final dictionary = ref.watch(dictionaryProvider).valueOrNull ?? glossary;
            final fromGlossary = searching
                // 辞書は約2,000語あるので、多すぎないように最初の30語だけ出す
                ? dictionary.values.where((w) => !savedTexts.contains(w.text) && wordMatches(w, _query)).take(30).toList()
                : const <Word>[];

            return VocabPage(
              title: '単語帳',
              trailing: '${all.length}語',
              showBack: false,
              children: [
                VocabFilledButton(
                  label: '復習する',
                  icon: Icons.style_rounded,
                  onPressed: all.isEmpty ? null : () => context.push(VocabRoutes.review),
                ),
                const SizedBox(height: 16),
                WordSearchField(controller: _search, onChanged: (v) => setState(() => _query = v)),
                const SizedBox(height: 14),
                if (all.isEmpty && !searching)
                  const _EmptyState()
                else if (saved.isEmpty && fromGlossary.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text(
                      '見つかりません',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: VocabStyle.muted),
                    ),
                  )
                else ...[
                  for (final w in saved) tile(w),
                  if (fromGlossary.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      '辞書から（押すと単語帳に追加できます）',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: VocabStyle.muted),
                    ),
                    const SizedBox(height: 10),
                    for (final w in fromGlossary) tile(w),
                  ],
                ],
              ],
            );
          },
        );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.bookmark_border_rounded, size: 56, color: VocabStyle.muted),
          SizedBox(height: 12),
          Text('まだ単語がありません', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          SizedBox(height: 4),
          Text(
            '上で検索して、用語集の単語を追加できます',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VocabStyle.muted),
          ),
        ],
      ),
    );
  }
}
