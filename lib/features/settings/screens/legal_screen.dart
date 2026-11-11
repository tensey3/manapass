import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/legal_text.dart';
import '../widgets/settings_page.dart';

enum LegalDoc { terms, privacy }

/// 利用規約 / プライバシーポリシー。
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    final (title, sections) = switch (doc) {
      LegalDoc.terms => ('利用規約', termsJa),
      LegalDoc.privacy => ('プライバシーポリシー', privacyJa),
    };

    return SettingsPage(
      title: title,
      children: [
        Text(
          '最終更新日：${DateFormat.yMMMEd('ja').format(legalLastUpdated)}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SettingsStyle.muted),
        ),
        const SizedBox(height: 12),
        const NoteBox('下書き：公開前に、チームと先生が内容を確認します。', icon: Icons.edit_note_rounded),
        const SizedBox(height: 18),
        SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) const SizedBox(height: 22),
                Text(
                  '${i + 1}. ${sections[i].title}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(sections[i].body, style: const TextStyle(fontSize: 14, height: 1.8)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
