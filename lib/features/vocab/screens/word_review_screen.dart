import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vocab_data.dart';
import '../providers/wordbook_controller.dart';
import '../widgets/vocab_page.dart';
import '../widgets/word_label_chip.dart';

/// 単語帳の単語のカード。カードを押すと意味が見える。
/// そのあと「まだ」か「覚えた」を選ぶ。最後に覚えた数を表示する。
class WordReviewScreen extends ConsumerWidget {
  const WordReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(savedWordsProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const Center(child: Text('読み込みに失敗しました')),
          data: (words) => words.isEmpty
              ? const Center(child: Text('まだ単語がありません'))
              // 始めたときの単語で最後まで進める（途中で単語帳が変わっても変えない）
              : _Review(words: words),
        );
  }
}

class _Review extends StatefulWidget {
  const _Review({required this.words});

  final List<Word> words;

  @override
  State<_Review> createState() => _ReviewState();
}

class _ReviewState extends State<_Review> {
  late final List<Word> _words = widget.words;
  int _index = 0;
  int _known = 0;
  bool _flipped = false;

  int get _total => _words.length;
  bool get _done => _index >= _total;

  void _answer({required bool known}) {
    setState(() {
      if (known) _known++;
      _index++;
      _flipped = false;
    });
  }

  void _restart() => setState(() {
        _index = 0;
        _known = 0;
        _flipped = false;
      });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 20, 6),
          child: Row(
            children: [
              IconButton(
                onPressed: () => vocabBack(context),
                tooltip: '閉じる',
                icon: const Icon(Icons.close_rounded, color: VocabStyle.muted, size: 28),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _index / _total,
                    minHeight: 12,
                    color: VocabStyle.correct,
                    backgroundColor: VocabStyle.soft,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_done ? _total : _index + 1}/$_total',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: VocabStyle.muted),
              ),
            ],
          ),
        ),
        Expanded(child: _done ? _doneView() : _cardView()),
      ],
    );
  }

  Widget _cardView() {
    final word = _words[_index];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'カードをめくる',
                  child: GestureDetector(
                    onTap: () => setState(() => _flipped = !_flipped),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: Tween(begin: 0.96, end: 1.0).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Container(
                        key: ValueKey('$_index-$_flipped'),
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(VocabStyle.cardRadius),
                          boxShadow: VocabStyle.cardShadow,
                        ),
                        child: SizedBox.expand(child: _flipped ? _back(word) : _front(word)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_flipped)
                Row(
                  children: [
                    Expanded(child: VocabOutlinedButton(label: 'まだ', onPressed: () => _answer(known: false))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: VocabFilledButton(
                        label: '覚えた',
                        color: VocabStyle.correct,
                        onPressed: () => _answer(known: true),
                      ),
                    ),
                  ],
                )
              else
                VocabFilledButton(label: '答えを見る', onPressed: () => setState(() => _flipped = true)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _front(Word word) {
    return Stack(
      children: [
        Center(
          child: Text(
            word.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, height: 1.3),
          ),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: Text(
            'タップしてめくる',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VocabStyle.muted),
          ),
        ),
      ],
    );
  }

  Widget _back(Word word) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (word.reading != null)
            Text(
              word.reading!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: VocabStyle.muted),
            ),
          Text(
            word.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1.3),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18, horizontal: 40),
            child: Divider(color: VocabStyle.line, thickness: 2),
          ),
          Text(
            word.meaning,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          WordLabelChip(label: word.label),
        ],
      ),
    );
  }

  Widget _doneView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: _known / _total,
                      strokeWidth: 18,
                      strokeCap: StrokeCap.round,
                      color: VocabStyle.correct,
                      backgroundColor: VocabStyle.line,
                    ),
                    Center(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: '$_known',
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
                          ),
                          TextSpan(
                            text: '/$_total',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: VocabStyle.muted),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('おつかれさま！', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Text(
                '覚えた単語 $_known語',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: VocabStyle.muted),
              ),
              const SizedBox(height: 28),
              VocabFilledButton(label: 'もどる', onPressed: () => vocabBack(context)),
              const SizedBox(height: 12),
              VocabOutlinedButton(label: 'もう一度', onPressed: _restart),
            ],
          ),
        ),
      ),
    );
  }
}
