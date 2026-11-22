import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/question.dart';
import 'question_answer_screen.dart';

/// 解き終わったときの結果：正解数、1問ずつの ○×、間違えた問題の解き直し。
class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.correct,
    this.passLine,
  });

  final String title;
  final List<Question> questions;
  final List<bool> correct; // questions と同じ順
  final double? passLine; // 模擬試験の合格の目安（0.6 など）。null なら出さない

  @override
  Widget build(BuildContext context) {
    final total = questions.length;
    final score = correct.where((c) => c).length;
    final rate = total == 0 ? 0.0 : score / total;
    final wrong = [
      for (var i = 0; i < total; i++)
        if (!correct[i]) questions[i],
    ];
    final passed = passLine == null ? null : rate >= passLine!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: '閉じる',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('結果', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Text('$score / $total 問 正解',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              Text('正答率 ${(rate * 100).round()}%',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
              if (passed != null) ...[
                const SizedBox(height: 10),
                Text(
                  passed ? '合格ライン（${(passLine! * 100).round()}%）に届きました' : '合格ライン（${(passLine! * 100).round()}%）まであと少し',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: passed ? AppColors.success : const Color(0xFFE5484D),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              for (var i = 0; i < total; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.track),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        correct[i] ? Icons.circle_outlined : Icons.close_rounded,
                        color: correct[i] ? AppColors.success : const Color(0xFFE5484D),
                      ),
                      const SizedBox(width: 12),
                      if (questions[i].number != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text('問${questions[i].number}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      Expanded(
                        child: Text(
                          questions[i].questionText.replaceAll('\n', ' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              if (wrong.isNotEmpty)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => QuestionAnswerScreen(title: '$title（解き直し）', questions: wrong),
                    ),
                  ),
                  child: Text('間違えた${wrong.length}問を解き直す', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
