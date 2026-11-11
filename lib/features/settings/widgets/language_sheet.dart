import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_controller.dart';
import 'settings_page.dart';

/// 言語の名前は、それぞれの言語で書く。
const languageNames = {'ja': '日本語', 'en': 'English'};

/// 下から出る 日本語 / English の選択シート。
void showLanguageSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final current = ref.watch(settingsProvider).valueOrNull?.language;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 10),
                  child: Text('言語', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ),
                for (final MapEntry(key: code, value: name) in languageNames.entries)
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SettingsStyle.smallRadius)),
                    title: Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    trailing: current == code
                        ? const Icon(Icons.check_circle_rounded, color: SettingsStyle.primary)
                        : null,
                    onTap: () {
                      ref.read(settingsProvider.notifier).setLanguage(code);
                      Navigator.pop(sheetContext);
                    },
                  ),
                const SizedBox(height: 8),
                const NoteBox('選んだ言語は保存されます。アプリ全体の表示の切り替えは、今後対応予定です。'),
              ],
            ),
          ),
        );
      },
    ),
  );
}
