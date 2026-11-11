import 'package:flutter/material.dart';

import 'settings_page.dart';

/// はい / いいえ の確認。[ok] を押したら true を返す。
/// [danger] は元に戻せない操作用（ボタンが赤くなる）。
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String ok,
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SettingsStyle.cardRadius)),
      title: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      content: message == null
          ? null
          : Text(message, style: const TextStyle(fontSize: 15, color: SettingsStyle.muted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'キャンセル',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: SettingsStyle.muted),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            ok,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: danger ? SettingsStyle.wrongText : SettingsStyle.primaryText,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
