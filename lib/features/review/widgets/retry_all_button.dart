import 'package:flutter/material.dart';

/// まとめて解き直すボタン（設計書 No.10）
/// 無効になる条件：復習対象が0問（バリデーション）／onPressed が null。
class RetryAllButton extends StatelessWidget {
  const RetryAllButton({
    super.key,
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: count >= 1 ? onPressed : null,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text(
          'まとめて解き直す',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF3B9EFF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
