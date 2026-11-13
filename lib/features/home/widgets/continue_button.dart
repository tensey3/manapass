import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 青い角丸の「続きから」ボタン。
/// スマホでは横幅いっぱいにするため、width を変えられる。
class ContinueButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double width;
  const ContinueButton({super.key, this.onPressed, this.width = 456});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: 48,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      onPressed: onPressed,
      child: const Text('続きから', style: TextStyle(fontSize: 15)),
    ),
  );
}
