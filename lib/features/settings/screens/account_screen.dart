import 'package:flutter/material.dart';

import '../widgets/confirm_dialog.dart';
import '../widgets/settings_page.dart';
import '../widgets/settings_tile.dart';

/// 今はログイン機能がないので、見本のユーザーを表示する。
/// ログイン機能ができたら、本物のアカウント情報に置き換える。
const sampleUser = (name: 'Linh', email: 'linh@example.com', signInMethod: 'Google');

/// アカウント：ログイン中のユーザー、同期、ログアウト、アカウント削除。
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void _notReady(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ログイン機能は準備中です')));
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showConfirmDialog(context, title: 'ログアウトしますか？', ok: 'ログアウト');
    if (ok && context.mounted) _notReady(context);
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'アカウントを削除しますか？',
      message: '学習記録と単語帳がすべて消えます。元に戻せません。',
      ok: '削除する',
      danger: true,
    );
    if (ok && context.mounted) _notReady(context);
  }

  @override
  Widget build(BuildContext context) {
    final name = sampleUser.name;
    return SettingsPage(
      title: 'アカウント',
      children: [
        SettingsCard(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: SettingsStyle.tint, shape: BoxShape.circle),
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: SettingsStyle.primaryText),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    Text(
                      sampleUser.email,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: SettingsStyle.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SettingsGroup(
          children: [
            SettingsRow(icon: Icons.login_rounded, title: 'ログイン方法', value: sampleUser.signInMethod),
            const SettingsRow(
              icon: Icons.cloud_done_rounded,
              title: 'データの同期',
              subtitle: '学習記録はアカウントに保存されます',
              value: '済み',
              color: SettingsStyle.correct,
            ),
          ],
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 54,
          child: OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('ログアウト', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            style: OutlinedButton.styleFrom(
              foregroundColor: SettingsStyle.primaryText,
              backgroundColor: Colors.white,
              side: const BorderSide(color: SettingsStyle.line, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SettingsStyle.buttonRadius)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => _delete(context),
            child: const Text(
              'アカウントを削除',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: SettingsStyle.wrongText),
            ),
          ),
        ),
      ],
    );
  }
}
