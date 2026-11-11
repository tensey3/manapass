import 'package:flutter/material.dart';

import 'settings_page.dart';

/// グレーの枠の中から1つ選ぶボタン（例：小 / 中 / 大、ライト / ダーク）。
class PillTabs extends StatelessWidget {
  const PillTabs({super.key, required this.options, required this.selected, required this.onChanged});

  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SettingsStyle.soft,
        borderRadius: BorderRadius.circular(SettingsStyle.smallRadius + 4),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: i == selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(SettingsStyle.smallRadius),
                  boxShadow: i == selected ? SettingsStyle.cardShadow : null,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () => onChanged(i),
                    borderRadius: BorderRadius.circular(SettingsStyle.smallRadius),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        options[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: i == selected ? SettingsStyle.primaryText : SettingsStyle.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
