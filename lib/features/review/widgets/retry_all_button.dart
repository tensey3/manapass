import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 「まとめて解き直す」ボタン。
class RetryAllButton extends StatelessWidget {
  final int count;
  final VoidCallback? onPressed;
  const RetryAllButton({super.key, required this.count, this.onPressed});

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    onPressed: count == 0 ? null : onPressed,
    icon: const Icon(Icons.replay, size: 18),
    label: Text('まとめて解き直す（$count問）'),
  );
}
