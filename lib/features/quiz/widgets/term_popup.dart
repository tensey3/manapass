import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../vocab/providers/dictionary_controller.dart';
import '../../vocab/providers/lookup_controller.dart';
import '../../vocab/providers/vocab_detail_controller.dart';
import '../../vocab/providers/wordbook_controller.dart';
import '../../vocab/widgets/word_label_chip.dart';
import '../../vocab/widgets/wordbook_toggle_button.dart';

/// 問題の中の単語を押したときに出る、読みと意味。単語帳に追加できる。
Future<void> showTermPopup(BuildContext context, String word) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => TermPopup(word: word),
  );
}

class TermPopup extends ConsumerStatefulWidget {
  const TermPopup({super.key, required this.word});

  final String word;

  @override
  ConsumerState<TermPopup> createState() => _TermPopupState();
}

class _TermPopupState extends ConsumerState<TermPopup> {
  int? _lookupsBefore; // 開く前に何回調べていたか（「英語を少しずつ減らす」で使う）
  bool _showEnglish = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final counts = await ref.read(lookupCountsProvider.future);
      if (!mounted) return;
      setState(() => _lookupsBefore = counts[widget.word] ?? 0);
      await ref.read(lookupCountsProvider.notifier).record(widget.word);
    });
  }

  @override
  Widget build(BuildContext context) {
    final word = ref.watch(dictionaryProvider).valueOrNull?[widget.word];
    final saved = ref.watch(wordbookProvider).valueOrNull ?? const [];
    final settings = ref.watch(vocabSettingsProvider);
    if (word == null) {
      return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
    }
    final hide = !_showEnglish &&
        shouldHideEnglish(reduceEnglish: settings.reduceEnglish, lookups: _lookupsBefore ?? 0);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(child: Text(word.text, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
                if (word.reading != null) ...[
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(word.reading!, style: const TextStyle(fontSize: 16, color: AppColors.textMuted)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: WordLabelChip(label: word.label)),
            const SizedBox(height: 14),
            if (hide)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showEnglish = true),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('英語の意味を見る'),
                ),
              )
            else
              Text(word.meaning, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.5)),
            const SizedBox(height: 18),
            WordbookToggleButton(
              isSaved: saved.contains(word.text),
              onPressed: () => ref.read(wordbookProvider.notifier).toggle(word.text),
            ),
          ],
        ),
      ),
    );
  }
}
