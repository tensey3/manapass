import 'package:flutter/material.dart';

import '../data/theme_options.dart';
import '../widgets/settings_page.dart';
import 'settings_screen.dart';

/// 出典・ライセンス：問題や辞書データ、フォントの出典。
/// IPAの過去問題を使うときは、出典の表示が必要。
/// 一番下から、Flutterのオープンソースライセンス一覧を開ける。
class LicenseScreen extends StatelessWidget {
  const LicenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: '出典・ライセンス',
      children: [
        const _Section(
          icon: Icons.menu_book_rounded,
          title: '過去問題',
          body: '出典：独立行政法人 情報処理推進機構（IPA）基本情報技術者試験 公開問題。内容を変えた問題には「改変」と表示します。',
          note: '今はサンプル問題のみです（IPAの問題ではありません）。',
        ),
        const SizedBox(height: 14),
        const _Section(
          icon: Icons.translate_rounded,
          title: '辞書データ',
          body: '辞書データを使うときは、ここに出典とライセンスを表示します。',
        ),
        const SizedBox(height: 14),
        _Section(
          icon: Icons.text_fields_rounded,
          title: 'フォント',
          body: 'Google Fonts（SIL Open Font License 1.1）\n${fontFamilies.map((f) => '・$f').join('\n')}',
        ),
        const SizedBox(height: 22),
        Center(
          child: TextButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'まなパス',
              applicationVersion: appVersion,
            ),
            child: const Text(
              'オープンソースライセンス',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: SettingsStyle.muted),
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.body, this.note});

  final IconData icon;
  final String title;
  final String body;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: SettingsStyle.primary, size: 22),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.7)),
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(
              note!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SettingsStyle.warningText),
            ),
          ],
        ],
      ),
    );
  }
}
