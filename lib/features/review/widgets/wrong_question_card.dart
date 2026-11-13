import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

import '../providers/review_data_source.dart';

/// 間違えた問題カード。タップで自分の解答・正解・解説を開閉。
class WrongQuestionCard extends StatelessWidget {
  final WrongQuestion question;
  final VoidCallback? onRetry;
  const WrongQuestionCard({super.key, required this.question, this.onRetry});

  @override
  // 白い背景は Container ではなく Material で描く。
  // （Container の背景色だと ExpansionTile の上でエラーになるため）
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEDEFF2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: const Icon(Icons.close_rounded, color: Color(0xFFFF3B30)),
          title: Text(
            question.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            question.category,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
          children: [
            _line('あなたの解答', question.userChoice, const Color(0xFFFF3B30)),
            const SizedBox(height: 6),
            _line('正解', question.correctAnswer, AppColors.success),
            if (question.explanation != null) ...[
              const SizedBox(height: 10),
              Text(
                question.explanation!,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('この問題を解き直す'),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _line(String label, String value, Color color) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 90,
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
