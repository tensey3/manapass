import 'package:flutter/material.dart';

import 'settings_page.dart';

/// パスワードを入れてもらってから、元に戻せない操作をする確認画面。
/// [onConfirm] は失敗したらメッセージを、成功したら null を返す。
/// 成功したら true を返して閉じる。キャンセルしたら false。
Future<bool> showPasswordConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String ok,
  required Future<String?> Function(String password) onConfirm,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _PasswordConfirmDialog(title: title, message: message, ok: ok, onConfirm: onConfirm),
  );
  return result ?? false;
}

class _PasswordConfirmDialog extends StatefulWidget {
  const _PasswordConfirmDialog({required this.title, required this.message, required this.ok, required this.onConfirm});

  final String title;
  final String message;
  final String ok;
  final Future<String?> Function(String password) onConfirm;

  @override
  State<_PasswordConfirmDialog> createState() => _PasswordConfirmDialogState();
}

class _PasswordConfirmDialogState extends State<_PasswordConfirmDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidden = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'パスワードを入力してください');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onConfirm(_password.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SettingsStyle.cardRadius)),
      title: Text(widget.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.message, style: const TextStyle(fontSize: 15, color: SettingsStyle.muted)),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            enabled: !_busy,
            obscureText: _hidden,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'パスワード',
              errorText: _error,
              errorMaxLines: 3,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(SettingsStyle.smallRadius)),
              suffixIcon: IconButton(
                tooltip: _hidden ? 'パスワードを表示' : 'パスワードを隠す',
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(_hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text(
            'キャンセル',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: SettingsStyle.muted),
          ),
        ),
        TextButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
              : Text(
                  widget.ok,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: SettingsStyle.wrongText),
                ),
        ),
      ],
    );
  }
}
