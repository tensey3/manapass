import 'package:flutter/material.dart';

import '../data/theme_options.dart';
import 'settings_page.dart';

/// テーマカラーの丸を並べたもの。選ぶとチェックが付く。
class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({super.key, required this.selectedId, required this.onChanged});

  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final preset in themePresets)
          _ColorDot(
            preset: preset,
            selected: preset.id == selectedId,
            onTap: () => onChanged(preset.id),
          ),
      ],
    );
  }
}

/// 丸い色見本：メインの色と、小さいアクセントの点。
class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.preset, required this.selected, required this.onTap});

  final ThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: preset.name,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 68,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? SettingsStyle.ink : Colors.transparent, width: 3),
                ),
                child: Container(
                  decoration: BoxDecoration(color: preset.primary, shape: BoxShape.circle),
                  alignment: Alignment.bottomRight,
                  child: selected
                      ? const Center(child: Icon(Icons.check_rounded, color: Colors.white, size: 26))
                      : Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: preset.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                preset.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: selected ? SettingsStyle.ink : SettingsStyle.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
