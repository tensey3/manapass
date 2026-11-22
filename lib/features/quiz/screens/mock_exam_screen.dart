import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/question.dart';
import '../../../data/repositories/question_repository.dart';
import '../widgets/option_button.dart';
import '../widgets/question_body.dart';
import 'quiz_result_screen.dart';

/// 模擬試験：時間内に全部答えて、最後にまとめて答え合わせ。
/// 途中では正解を出さない。時間切れになったら自動で提出する。
class MockExamSessionScreen extends ConsumerStatefulWidget {
  const MockExamSessionScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.timeLimit,
    this.passLine = 0.6,
  });

  final String title;
  final List<Question> questions;
  final Duration timeLimit;
  final double passLine;

  @override
  ConsumerState<MockExamSessionScreen> createState() => _MockExamSessionScreenState();
}

class _MockExamSessionScreenState extends ConsumerState<MockExamSessionScreen> {
  final _scroll = ScrollController();
  final _answers = <int, int>{}; // 何問目 → 選んだ番号
  late final DateTime _end = DateTime.now().add(widget.timeLimit);
  Timer? _timer;
  Duration _left = Duration.zero;
  int _index = 0;
  bool _submitting = false;

  Question get _q => widget.questions[_index];
  int get _total => widget.questions.length;

  @override
  void initState() {
    super.initState();
    _left = widget.timeLimit;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _end.difference(DateTime.now());
      if (left <= Duration.zero) {
        _timer?.cancel();
        _submit();
      } else {
        setState(() => _left = left);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _go(int index) {
    setState(() => _index = index.clamp(0, _total - 1));
    _scroll.jumpTo(0);
  }

  Future<void> _confirmSubmit() async {
    final unanswered = _total - _answers.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提出しますか？'),
        content: Text(unanswered > 0 ? 'まだ答えていない問題が$unanswered問あります。答えていない問題は不正解になります。' : '答え合わせをします。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('戻る')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('提出する')),
        ],
      ),
    );
    if (ok == true) await _submit();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    _submitting = true;
    _timer?.cancel();
    // 答えた問題だけ記録する（進捗・復習で使う）。記録できなくても結果は出す。
    final repository = ref.read(questionRepositoryProvider);
    var failed = false;
    for (final entry in _answers.entries) {
      try {
        await repository.recordAnswer(widget.questions[entry.key], entry.value);
      } catch (_) {
        failed = true;
      }
    }
    if (!mounted) return;
    if (failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('解答を記録できなかった問題があります（進捗には反映されません）')),
      );
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QuizResultScreen(
          title: widget.title,
          questions: widget.questions,
          correct: [
            for (var i = 0; i < _total; i++) _answers[i] == widget.questions[i].answerIndex,
          ],
          passLine: widget.passLine,
        ),
      ),
    );
  }

  Future<void> _confirmQuit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('模擬試験をやめますか？'),
        content: const Text('ここまでの解答は記録されません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('続ける')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('やめる')),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop();
  }

  void _openList() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('問題一覧（答えた問題 ${_answers.length}/$_total）', style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _total; i++)
                    SizedBox(
                      width: 52,
                      height: 44,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: _answers.containsKey(i) ? AppColors.menuSelectedBg : null,
                          side: BorderSide(color: i == _index ? AppColors.primary : AppColors.track, width: 2),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _go(i);
                        },
                        child: Text('${i + 1}'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mm = _left.inMinutes.toString().padLeft(2, '0');
    final ss = (_left.inSeconds % 60).toString().padLeft(2, '0');
    final hurry = _left < const Duration(minutes: 5);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _confirmQuit,
                      tooltip: 'やめる',
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 28),
                    ),
                    Expanded(
                      child: Text('${_index + 1} / $_total',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                    Icon(Icons.timer_outlined, color: hurry ? const Color(0xFFE5484D) : AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('$mm:$ss',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: hurry ? const Color(0xFFE5484D) : AppColors.textStrong,
                        )),
                    const SizedBox(width: 8),
                    TextButton(onPressed: _openList, child: const Text('一覧')),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          QuestionBody(question: _q),
                          const SizedBox(height: 8),
                          ChoicesView(
                            question: _q,
                            stateOf: (i) => _answers[_index] == i ? ChoiceState.selected : ChoiceState.idle,
                            onSelect: (i) => setState(() => _answers[_index] = i),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.track, width: 2))),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: _index == 0 ? null : () => _go(_index - 1),
                      child: const Text('前へ'),
                    ),
                    const Spacer(),
                    if (_index < _total - 1)
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () => _go(_index + 1),
                        child: const Text('次へ'),
                      )
                    else
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                        onPressed: _confirmSubmit,
                        child: const Text('提出する'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
