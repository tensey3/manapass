import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/vocab_detail_controller.dart';
import '../providers/wordbook_controller.dart';
import '../widgets/related_question_card.dart';
import '../widgets/vocab_page.dart';
import '../widgets/word_label_chip.dart';
import '../widgets/wordbook_toggle_button.dart';

/// 単語1つ：読み、意味、出てくる問題、単語帳への追加 / 削除。
class VocabDetailScreen extends ConsumerWidget {
  const VocabDetailScreen({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(vocabDetailProvider(text)).when(
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
            return VocabPage(
              children: [
                if (word.reading != null)
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '意味',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: VocabStyle.muted),
                      ),
                      const SizedBox(height: 6),
                      Text(word.meaning, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('出てくる問題', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                if (detail.questions.isEmpty)
                  const Text('まだありません', style: TextStyle(fontSize: 14, color: VocabStyle.muted))
                else
                  for (final q in detail.questions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RelatedQuestionCard(question: q),
                    ),
                const SizedBox(height: 24),
                WordbookToggleButton(
                  isSaved: detail.isSaved,
                  onPressed: () => ref.read(wordbookProvider.notifier).toggle(word.text),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('報告しました')),
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
}
