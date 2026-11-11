import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/theme_options.dart';
import '../providers/exam_goal_controller.dart';
import '../providers/settings_controller.dart';
import '../settings_routes.dart';
import '../widgets/language_sheet.dart';
import '../widgets/settings_page.dart';
import '../widgets/settings_tile.dart';
import 'account_screen.dart';

/// 設定：アカウント、学習、表示（見た目と言語）、このアプリについて。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final goal = ref.watch(examGoalProvider).valueOrNull;

    return SettingsPage(
      title: '設定',
      showBack: false,
      children: [
        SettingsGroup(
          children: [
            SettingsRow(
              icon: Icons.person_rounded,
              title: 'アカウント',
              value: sampleUser.name,
              onTap: () => context.push(SettingsRoutes.account),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SettingsGroup(
          title: '学習',
          children: [
            SettingsRow(
              icon: Icons.event_rounded,
              title: '試験日と目標',
              value: goal == null ? null : DateFormat.MMMEd('ja').format(goal.examDate),
              onTap: () => context.push(SettingsRoutes.examGoal),
            ),
            SettingsRow(
              icon: Icons.translate_rounded,
              title: 'ふりがな・英語サポート',
              value: settings == null ? null : (settings.furigana ? 'オン' : 'オフ'),
              onTap: () => context.push(SettingsRoutes.furigana),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SettingsGroup(
          title: '表示',
          children: [
            SettingsRow(
              icon: Icons.palette_rounded,
              title: '見た目',
              value: settings == null ? null : themePresetOf(settings.themeId).name,
              onTap: () => context.push(SettingsRoutes.appearance),
            ),
            SettingsRow(
              icon: Icons.language_rounded,
              title: '言語',
              value: settings == null ? null : languageNames[settings.language],
              onTap: () => showLanguageSheet(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SettingsGroup(
          title: 'このアプリについて',
          children: [
            SettingsRow(
              icon: Icons.description_outlined,
              title: '利用規約',
              color: SettingsStyle.muted,
              onTap: () => context.push(SettingsRoutes.terms),
            ),
            SettingsRow(
              icon: Icons.privacy_tip_outlined,
              title: 'プライバシーポリシー',
              color: SettingsStyle.muted,
              onTap: () => context.push(SettingsRoutes.privacy),
            ),
            SettingsRow(
              icon: Icons.source_outlined,
              title: '出典・ライセンス',
              subtitle: 'IPA 過去問題・辞書データなど',
              color: SettingsStyle.muted,
              onTap: () => context.push(SettingsRoutes.licenses),
            ),
            const SettingsRow(
              icon: Icons.info_outline_rounded,
              title: 'バージョン',
              value: appVersion,
              color: SettingsStyle.muted,
            ),
          ],
        ),
      ],
    );
  }
}

const appVersion = '1.0.0';
