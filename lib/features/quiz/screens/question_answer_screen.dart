import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/question.dart';
import '../../../data/repositories/question_repository.dart';
import '../../home/providers/home_controller.dart';
import '../../question/providers/question_list_controller.dart';
import '../widgets/judge_banner.dart';
import '../widgets/option_button.dart';
import '../widgets/question_body.dart';
import 'quiz_result_screen.dart';

/// 問題を解く画面を、サイドメニューなしの全画面で開く。
/// 閉じたら、問題一覧の「解いた数」とホームの数字を読み直す。
Future<void> openQuiz(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required List<Question> questions,
  int startIndex = 0,
}) async {
  if (questions.isEmpty) return;
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => QuestionAnswerScreen(title: title, questions: questions, startIndex: startIndex),
    ),
  );
  refreshAnswerCounts(ref);
}

/// 解答の記録が増えたので、それを使っている画面の数字を読み直す。
void refreshAnswerCounts(WidgetRef ref) {
  ref.invalidate(answerRecordsProvider);
  ref.invalidate(homeProvider);
}

/// 1問ずつ解く：選ぶ → 解答する → 正解/不正解 → 次へ。最後まで行くと結果画面。
class QuestionAnswerScreen extends ConsumerStatefulWidget {
  const QuestionAnswerScreen({super.key, required this.title, required this.questions, this.startIndex = 0});

  final String title;
  final List<Question> questions;
  final int startIndex;

  @override
  ConsumerState<QuestionAnswerScreen> createState() => _QuestionAnswerScreenState();
}

class _QuestionAnswerScreenState extends ConsumerState<QuestionAnswerScreen> {
  final _scroll = ScrollController();
  final _results = <int, bool>{}; // 問題の番号（何問目か） → 正解したか
  late int _index = widget.startIndex.clamp(0, widget.questions.length - 1);
  int? _selected;
  bool _answered = false;

  Question get _q => widget.questions[_index];
  bool get _correct => _selected == _q.answerIndex;
  bool get _isLast => _index == widget.questions.length - 1;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _submit() {
    final selected = _selected;
    if (selected == null) return;
    setState(() {
      _answered = true;
      _results[_index] = selected == _q.answerIndex;
    });
    _record(_q, selected);
  }

  /// 解答を記録する（進捗・復習・問題一覧・ホームがこの記録を使う）。
  /// 記録できなくても続けられるように、失敗はお知らせだけ出す。
  Future<void> _record(Question question, int selected) async {
    try {
      await ref.read(questionRepositoryProvider).recordAnswer(question, selected);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('解答を記録できませんでした（進捗には反映されません）')),
      );
    }
  }

  void _next() {
    if (_isLast) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => QuizResultScreen(
            title: widget.title,
            questions: [for (final i in _results.keys) widget.questions[i]],
            correct: _results.values.toList(),
          ),
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _answered = false;
    });
    _scroll.jumpTo(0);
  }

  ChoiceState _stateOf(int i) {
    if (!_answered) return i == _selected ? ChoiceState.selected : ChoiceState.idle;
    if (i == _q.answerIndex) return ChoiceState.correct;
    if (i == _selected) return ChoiceState.wrong;
    return ChoiceState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 上：閉じる・タイトル・何問目か
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: '閉じる',
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 28),
                  ),
                  Expanded(
                    child: Text(widget.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                  Text('${_index + 1} / $total',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_index + (_answered ? 1 : 0)) / total,
                  minHeight: 6,
                  backgroundColor: AppColors.track,
                  color: AppColors.primary,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_q.number != null)
                          Text('問${_q.number}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        QuestionBody(question: _q),
                        const SizedBox(height: 8),
                        ChoicesView(
                          question: _q,
                          stateOf: _stateOf,
                          onSelect: _answered ? null : (i) => setState(() => _selected = i),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!_answered)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.track, width: 2))),
                child: Center(
                  child: SizedBox(
                    width: 760,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _selected == null ? null : _submit,
                      child: const Text('解答する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              )
            else
              JudgeBanner(
                correct: _correct,
                answerLabel: choiceLabel(_q.answerIndex),
                nextLabel: _isLast ? '結果を見る' : '次へ',
                onNext: _next,
              ),
          ],
        ),
      ),
    );
  }
}
