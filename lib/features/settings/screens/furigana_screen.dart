import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_controller.dart';
import '../widgets/furigana_preview.dart';
import '../widgets/pill_tabs.dart';
import '../widgets/settings_page.dart';
import '../widgets/settings_tile.dart';

/// ふりがなのオン/オフと大きさ（見本つき）、「英語を少しずつ減らす」。
class FuriganaScreen extends ConsumerWidget {
  const FuriganaScreen({super.key});

  static const _sizes = [0.42, 0.5, 0.6]; // 小、中、大

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const title = 'ふりがな・英語サポート';
    return ref.watch(settingsProvider).when(
          loading: () => SettingsPage(title: title, children: [settingsLoading()]),
          error: (error, stackTrace) => SettingsPage(title: title, children: [settingsError()]),
          data: (settings) {
            final controller = ref.read(settingsProvider.notifier);
            return SettingsPage(
              title: title,
              children: [
                const SectionLabel('見え方'),
                SettingsCard(
                  child: FuriganaPreview(
                    '[排他制御|はいたせいぎょ]を[行|おこな]う[目的|もくてき]として、[最|もっと]も[適切|てきせつ]なものはどれか。',
                    size: 19,
                    showFurigana: settings.furigana,
                    rubyScale: settings.rubyScale,
                  ),
                ),
                const SizedBox(height: 18),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      icon: Icons.text_fields_rounded,
                      title: 'ふりがなを表示',
                      trailing: Switch(value: settings.furigana, onChanged: controller.setFurigana),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const SectionLabel('ふりがなの大きさ'),
                PillTabs(
                  options: const ['小', '中', '大'],
                  selected: _sizes.indexOf(settings.rubyScale).clamp(0, 2),
                  onChanged: (i) => controller.setRubyScale(_sizes[i]),
                ),
                const SizedBox(height: 26),
                const SectionLabel('英語サポート'),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      icon: Icons.trending_down_rounded,
                      title: '英語を少しずつ減らす',
                      subtitle: '3回調べた単語は、英語を隠します',
                      color: SettingsStyle.correct,
                      trailing: Switch(value: settings.reduceEnglish, onChanged: controller.setReduceEnglish),
                    ),
                  ],
                ),
              ],
            );
          },
        );
  }
}
