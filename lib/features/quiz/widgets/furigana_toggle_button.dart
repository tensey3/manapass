import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../settings/providers/settings_controller.dart';
import '../../vocab/providers/vocab_detail_controller.dart';

/// 問題を解く画面の上にある「ふりがな」のオン・オフ。設定画面の「ふりがな」と同じもの。
class FuriganaToggleButton extends ConsumerWidget {
  const FuriganaToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(vocabSettingsProvider).furigana;
    return Tooltip(
      message: on ? 'ふりがなを消す' : 'ふりがなを出す',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => ref.read(settingsProvider.notifier).setFurigana(!on),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: on ? AppColors.menuSelectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: on ? AppColors.menuSelectedBorder : AppColors.track),
          ),
          child: Text('ふりがな',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: on ? AppColors.menuSelectedText : AppColors.textMuted,
              )),
        ),
      ),
    );
  }
}
