import 'package:flutter/material.dart';

import '../data/theme_options.dart';
import 'settings_page.dart';

/// フォントの選択肢1つ。見本の文字はそのフォントで表示する。
class FontPickerRow extends StatelessWidget {
  const FontPickerRow({super.key, required this.family, required this.selected, required this.onTap});

  final String family;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(SettingsStyle.buttonRadius);
    return Material(
      color: selected ? SettingsStyle.tint : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: selected ? SettingsStyle.primary : SettingsStyle.line, width: 2),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'まなパス 学びの道',
                      style: fontStyle(family, fontSize: 20, fontWeight: FontWeight.w700, color: SettingsStyle.ink),
                    ),
                    Text(
                      family,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: SettingsStyle.muted),
                    ),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle_rounded, color: SettingsStyle.primary),
            ],
          ),
        ),
      ),
    );
  }
}
