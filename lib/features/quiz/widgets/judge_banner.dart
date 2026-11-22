import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 解答したあと、画面の下に出る「正解！ / 不正解」と「次へ」。
class JudgeBanner extends StatelessWidget {
  const JudgeBanner({
    super.key,
    required this.correct,
    required this.answerLabel,
    required this.nextLabel,
    required this.onNext,
  });

  final bool correct;
  final String answerLabel; // 正解の記号（ア など）
  final String nextLabel;
  final VoidCallback onNext;

  static const _wrongColor = Color(0xFFE5484D);

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.success : _wrongColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.10), Colors.white),
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.4), width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(correct ? Icons.check_rounded : Icons.close_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(correct ? '正解！' : '不正解',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color)),
                      if (!correct)
                        Text('正解は $answerLabel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    minimumSize: const Size(120, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: onNext,
                  child: Text(nextLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
