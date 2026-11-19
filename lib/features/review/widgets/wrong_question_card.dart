import 'package:flutter/material.dart';

import '../providers/review_data_source.dart';

/// 間違えた問題カード（設計書 No.22〜30）：×アイコン・分野チップ・問題本文
/// ※既存の wrong_question_card.dart には触れないよう、別名で作成。
class WrongQuestionTile extends StatelessWidget {
  const WrongQuestionTile({super.key, required this.question, this.onTap});

  final WrongQuestion question;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(top: 2),
                decoration: const BoxDecoration(
                    color: Color(0xFFEF4444), shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F1FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        question.category,
                        style: t.bodySmall?.copyWith(
                            color: const Color(0xFF1E78D6),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(question.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
