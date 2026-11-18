import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../providers/account_controller.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/password_confirm_dialog.dart';
import '../widgets/settings_page.dart';
import '../widgets/settings_tile.dart';

/// アカウント：ログイン中のユーザー、同期、ログアウト、アカウント削除。
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(context, title: 'ログアウトしますか？', ok: 'ログアウト');
    if (!ok || !context.mounted) return;
    try {
      await signOut(ref);
    } catch (_) {
      if (context.mounted) _toast(context, 'ログアウトできませんでした。もう一度お試しください');
      return;
    }
    if (context.mounted) context.go(Routes.signIn);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    const title = 'アカウントを削除しますか？';
    const message = '学習記録と単語帳がすべて消えます。元に戻せません。';
    final deleted = await showPasswordConfirmDialog(
      context,
      title: title,
      message: '$message\n確認のため、パスワードを入力してください。',
      ok: '削除する',
      onConfirm: (password) => deleteAccount(ref, password: password),
    );
    if (!deleted || !context.mounted) return;
    _toast(context, 'アカウントを削除しました');
    context.go(Routes.signIn);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider);
    if (account == null) {
      return SettingsPage(
        title: 'アカウント',
        children: [
          const NoteBox('ログインしていません。ログインすると、学習記録がアカウントに保存されます。'),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: () => context.go(Routes.signIn),
              icon: const Icon(Icons.login_rounded),
              label: const Text('ログイン', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              style: FilledButton.styleFrom(
                backgroundColor: SettingsStyle.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SettingsStyle.buttonRadius)),
              ),
            ),
          ),
        ],
      );
    }

    final name = account.name;
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
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    if (account.email.isNotEmpty)
                      Text(
                        account.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            SettingsRow(icon: Icons.login_rounded, title: 'ログイン方法', value: account.signInMethod),
            const SettingsRow(
              icon: Icons.cloud_done_rounded,
              title: 'データの同期',
              subtitle: '問題の解答記録はアカウントに保存されます',
              value: '済み',
              color: SettingsStyle.correct,
            ),
          ],
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 54,
          child: OutlinedButton.icon(
            onPressed: () => _logout(context, ref),
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
            onPressed: () => _delete(context, ref),
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
