import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/question.dart';
import '../providers/lookup_controller.dart';
import '../providers/related_questions_controller.dart';
import '../providers/vocab_detail_controller.dart';
import '../providers/wordbook_controller.dart';
import '../widgets/related_question_card.dart';
import '../widgets/vocab_page.dart';
import '../widgets/word_label_chip.dart';
import '../widgets/wordbook_toggle_button.dart';

/// 単語1つ：読み、意味、出てくる問題、単語帳への追加 / 削除。
/// 開くたびに「調べた回数」を1つ増やす（設定の「英語を少しずつ減らす」で使う）。
class VocabDetailScreen extends ConsumerStatefulWidget {
  const VocabDetailScreen({super.key, required this.text});

  final String text;

  /// 出てくる問題を、最初に何問まで見せるか。
  static const shownQuestions = 5;

  @override
  ConsumerState<VocabDetailScreen> createState() => _VocabDetailScreenState();
}

class _VocabDetailScreenState extends ConsumerState<VocabDetailScreen> {
  int? _lookupsBefore; // このページを開く前に調べた回数（開いている間は変えない）
  bool _showEnglish = false; // 隠した英語を「見る」を押したか
  bool _showAllQuestions = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(vocabSettingsProvider);
    final lookups = ref.watch(lookupCountsProvider).valueOrNull;
    if (_lookupsBefore == null && lookups != null) {
      _lookupsBefore = lookups[widget.text] ?? 0;
      Future.microtask(() => ref.read(lookupCountsProvider.notifier).record(widget.text));
    }

    return ref.watch(vocabDetailProvider(widget.text)).when(
          loading: () => const VocabPage(
            children: [Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))],
          ),
          error: (error, stackTrace) => const VocabPage(
            children: [Padding(padding: EdgeInsets.all(40), child: Center(child: Text('読み込みに失敗しました')))],
          ),
          data: (detail) {
            if (detail == null) {
              return const VocabPage(
                children: [Padding(padding: EdgeInsets.all(40), child: Center(child: Text('この単語は見つかりません')))],
              );
            }
            final word = detail.word;
            final hideEnglish = !_showEnglish &&
                shouldHideEnglish(reduceEnglish: settings.reduceEnglish, lookups: _lookupsBefore ?? 0);
            return VocabPage(
              children: [
                if (settings.furigana && word.reading != null)
                  Text(
                    word.reading!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: VocabStyle.muted),
                  ),
                Text(
                  word.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: 1.3),
                ),
                const SizedBox(height: 10),
                Center(child: WordLabelChip(label: word.label)),
                const SizedBox(height: 24),
                VocabCard(
                  onTap: hideEnglish ? () => setState(() => _showEnglish = true) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '意味',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: VocabStyle.muted),
                      ),
                      const SizedBox(height: 6),
                      if (hideEnglish) ...[
                        const Text(
                          'この単語は3回以上調べたので、英語を隠しています。',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VocabStyle.muted),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'タップして英語を見る',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: VocabStyle.primaryText),
                        ),
                      ] else
                        Text(word.meaning, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('出てくる問題', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                ..._relatedQuestions(ref.watch(relatedQuestionsProvider(word.text)), word.text),
                const SizedBox(height: 24),
                WordbookToggleButton(
                  isSaved: detail.isSaved,
                  onPressed: () => ref.read(wordbookProvider.notifier).toggle(word.text),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('意味の誤りの報告は、準備中です')),
                    ),
                    child: const Text(
                      '意味の誤りを報告',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VocabStyle.muted),
                    ),
                  ),
                ),
              ],
            );
          },
        );
  }

  List<Widget> _relatedQuestions(AsyncValue<List<Question>> related, String word) {
    const muted = TextStyle(fontSize: 14, color: VocabStyle.muted);
    return related.when(
      loading: () => const [
        Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
      ],
      error: (error, stackTrace) => const [Text('問題を読み込めませんでした', style: muted)],
      data: (questions) {
        if (questions.isEmpty) return const [Text('この単語が出てくる問題は、まだありません', style: muted)];
        final shown = _showAllQuestions ? questions : questions.take(VocabDetailScreen.shownQuestions).toList();
        final rest = questions.length - shown.length;
        return [
          for (final q in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RelatedQuestionCard(question: q, word: word),
            ),
          if (rest > 0)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _showAllQuestions = true),
                child: Text(
                  'ほかに$rest問を見る',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: VocabStyle.primaryText),
                ),
              ),
            ),
        ];
      },
    );
  }
}
