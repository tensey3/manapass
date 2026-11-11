import 'package:flutter/material.dart';

import 'settings_page.dart';

/// 1日の目標：－ 数字 ＋ で [step] ずつ変える。
class GoalStepper extends StatelessWidget {
  const GoalStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 5,
    this.max = 100,
    this.step = 5,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: Row(
        children: [
          _RoundButton(
            icon: Icons.remove_rounded,
            tooltip: '減らす',
            onTap: value - step >= min ? () => onChanged(value - step) : null,
          ),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '$value',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: SettingsStyle.primary),
                ),
                const TextSpan(text: ' 問', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ]),
              textAlign: TextAlign.center,
            ),
          ),
          _RoundButton(
            icon: Icons.add_rounded,
            tooltip: '増やす',
            onTap: value + step <= max ? () => onChanged(value + step) : null,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: onTap == null ? SettingsStyle.soft : SettingsStyle.tint,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: onTap == null ? SettingsStyle.muted : SettingsStyle.primaryText),
          ),
        ),
      ),
    );
  }
}
