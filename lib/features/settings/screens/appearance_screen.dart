import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/theme_options.dart';
import '../providers/settings_controller.dart';
import '../widgets/color_picker_row.dart';
import '../widgets/font_picker_row.dart';
import '../widgets/furigana_preview.dart';
import '../widgets/pill_tabs.dart';
import '../widgets/settings_page.dart';

/// 見た目：テーマカラー、フォント、ライト / ダーク / 端末に合わせる。
/// 上の見本は、選んだらすぐに変わる。
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  static const _modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const title = '見た目';
    return ref.watch(settingsProvider).when(
          loading: () => SettingsPage(title: title, children: [settingsLoading()]),
          error: (error, stackTrace) => SettingsPage(title: title, children: [settingsError()]),
          data: (settings) {
            final controller = ref.read(settingsProvider.notifier);
            return SettingsPage(
              title: title,
              children: [
                const SectionLabel('見え方'),
                _Preview(settings: settings),
                const SizedBox(height: 12),
                const NoteBox('選んだ見た目は保存されます。アプリ全体への反映は、今後対応予定です。'),
                const SizedBox(height: 26),
                const SectionLabel('テーマカラー'),
                ColorPickerRow(selectedId: settings.themeId, onChanged: controller.setThemeId),
                const SizedBox(height: 26),
                const SectionLabel('フォント'),
                for (final family in fontFamilies)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FontPickerRow(
                      family: family,
                      selected: settings.font == family,
                      onTap: () => controller.setFont(family),
                    ),
                  ),
                const SizedBox(height: 16),
                const SectionLabel('モード'),
                PillTabs(
                  options: const ['ライト', 'ダーク', '端末に合わせる'],
                  selected: _modes.indexOf(settings.themeMode),
                  onChanged: (i) => controller.setThemeMode(_modes[i]),
                ),
              ],
            );
          },
        );
  }
}

/// アプリの小さな見本：問題文、選んだ選択肢、ボタン。選んだ色・フォント・モードで表示する。
class _Preview extends StatelessWidget {
  const _Preview({required this.settings});

  final SettingsState settings;

  @override
  Widget build(BuildContext context) {
    final preset = themePresetOf(settings.themeId);
    final dark = switch (settings.themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    final card = dark ? const Color(0xFF182537) : Colors.white;
    final ink = dark ? const Color(0xFFEDF2F8) : SettingsStyle.ink;
    final tint = Color.alphaBlend(preset.primary.withValues(alpha: dark ? 0.22 : 0.11), card);
    TextStyle font({double? size, FontWeight? weight, Color? color}) =>
        fontStyle(settings.font, fontSize: size, fontWeight: weight, color: color ?? ink);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(SettingsStyle.cardRadius),
        boxShadow: SettingsStyle.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FuriganaPreview(
            '[排他制御|はいたせいぎょ]を[行|おこな]う[目的|もくてき]はどれか。',
            size: 17,
            showFurigana: settings.furigana,
            rubyScale: settings.rubyScale,
            style: font(),
          ),
          const SizedBox(height: 14),
          // 選択中の選択肢
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(SettingsStyle.buttonRadius),
              border: Border.all(color: preset.primary, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: preset.primary, shape: BoxShape.circle),
                  child: Text('ア', style: font(size: 16, weight: FontWeight.w900, color: Colors.white)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: FuriganaPreview(
                    'データの[整合性|せいごうせい]を[守|まも]る',
                    size: 16,
                    showFurigana: settings.furigana,
                    rubyScale: settings.rubyScale,
                    style: font(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: preset.primary,
              borderRadius: BorderRadius.circular(SettingsStyle.buttonRadius),
            ),
            child: Text('次へ', style: font(size: 17, weight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
