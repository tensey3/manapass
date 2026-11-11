import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/vocab_data.dart';
import '../providers/wordbook_controller.dart';
import '../vocab_routes.dart';
import '../widgets/vocab_page.dart';
import '../widgets/word_search_field.dart';
import '../widgets/word_tile.dart';

/// 単語帳：保存した単語の一覧、検索、復習（カード）を始めるボタン。
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

  bool _matches(Word w) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return w.text.toLowerCase().contains(q) ||
        (w.reading?.contains(q) ?? false) ||
        w.meaning.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
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
            final shown = all.where(_matches).toList();
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
                if (all.isEmpty)
                  const _EmptyState()
                else ...[
                  WordSearchField(controller: _search, onChanged: (v) => setState(() => _query = v)),
                  const SizedBox(height: 14),
                  if (shown.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text(
                        '見つかりません',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: VocabStyle.muted),
                      ),
                    )
                  else
                    for (final w in shown)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: WordTile(word: w, onTap: () => context.push(VocabRoutes.word(w.text))),
                      ),
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
            '問題の中の単語をタップして追加できます',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VocabStyle.muted),
          ),
        ],
      ),
    );
  }
}
