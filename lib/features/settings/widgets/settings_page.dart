import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/theme/app_theme.dart';

/// 設定画面で使う色と角の丸さ。
abstract final class SettingsStyle {
  static const primary = AppColors.primary;
  static const ink = AppColors.textStrong;
  static const muted = AppColors.textMuted;
  static const correct = AppColors.success;
  static const tint = AppColors.menuSelectedBg; // 選択中の項目の薄い背景
  static const primaryText = AppColors.menuSelectedText; // 薄い背景の上の文字
  static const line = Color(0xFFE4E8EE);
  static const soft = Color(0xFFF2F5F9);
  static const wrongText = Color(0xFFC62828);
  static const warning = Color(0xFFF08C00);
  static const warningText = Color(0xFFB35C00);

  static const cardRadius = 22.0;
  static const buttonRadius = 16.0;
  static const smallRadius = 14.0;

  static const cardShadow = [
    BoxShadow(color: Color(0x0F0F1928), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x380F1928), offset: Offset(0, 10), blurRadius: 24, spreadRadius: -10),
  ];
}

/// 設定の各ページの枠：タイトル（と戻るボタン）＋中身。PCでは中央に読みやすい幅で表示。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.title, required this.children, this.showBack = true});

  final String title;
  final List<Widget> children;
  final bool showBack;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (showBack) ...[
                      IconButton(
                        onPressed: () => _back(context),
                        tooltip: '戻る',
                        icon: const Icon(Icons.arrow_back_rounded, color: SettingsStyle.ink),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 白いカード（影つき）。
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.child, this.padding = const EdgeInsets.all(22)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SettingsStyle.cardRadius),
        boxShadow: SettingsStyle.cardShadow,
      ),
      child: child,
    );
  }
}

/// 項目の上の小さい見出し（例：見え方、1日の目標）。
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
    );
  }
}

/// 黄色い注意書き（例：下書きです、今後対応予定です）。
class NoteBox extends StatelessWidget {
  const NoteBox(this.text, {super.key, this.icon = Icons.info_outline_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SettingsStyle.warning.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(SettingsStyle.smallRadius),
      ),
      child: Row(
        children: [
          Icon(icon, color: SettingsStyle.warningText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: SettingsStyle.warningText),
            ),
          ),
        ],
      ),
    );
  }
}

/// 読み込み中・失敗の表示。
Widget settingsLoading() => const Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: CircularProgressIndicator()),
    );

Widget settingsError() => const Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: Text('読み込みに失敗しました')),
    );
