import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/features/settings/providers/account_controller.dart';
import 'package:testflutter/features/settings/screens/account_screen.dart';

class _FakeUserInfo implements UserInfo {
  _FakeUserInfo(this.providerId);

  @override
  final String providerId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  _FakeUser({this.email, this.displayName, List<String> providers = const ['password']})
      : providerData = [for (final p in providers) _FakeUserInfo(p)];

  @override
  final String? email;

  @override
  final String? displayName;

  @override
  final List<UserInfo> providerData;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(AccountInfo? account) => ProviderScope(
      overrides: [accountProvider.overrideWithValue(account)],
      child: const MaterialApp(home: Scaffold(body: AccountScreen())),
    );

void main() {
  group('AccountInfo.fromUser', () {
    test('名前がなければ、メールの @ より前を名前にする', () {
      final info = AccountInfo.fromUser(_FakeUser(email: 'taro.yamada@example.com'));
      expect(info.name, 'taro.yamada');
      expect(info.email, 'taro.yamada@example.com');
      expect(info.signInMethod, 'メール');
    });

    test('名前があれば、その名前を使う', () {
      final info = AccountInfo.fromUser(_FakeUser(email: 'a@example.com', displayName: '  山田  '));
      expect(info.name, '山田');
    });

    test('メールも名前もなければ ゲスト', () {
      final info = AccountInfo.fromUser(_FakeUser(providers: const []));
      expect(info.name, 'ゲスト');
      expect(info.signInMethod, 'ゲスト');
    });
  });

  test('ログイン方法の名前', () {
    expect(signInMethodName(['password']), 'メール');
    expect(signInMethodName(['google.com', 'password']), 'Google・メール');
    expect(signInMethodName(['github.com']), 'github.com');
  });

  testWidgets('ログイン中のユーザーを表示する', (tester) async {
    await tester.pumpWidget(_app(const AccountInfo(name: 'taro', email: 'taro@example.com', signInMethod: 'メール')));

    expect(find.text('taro'), findsOneWidget);
    expect(find.text('taro@example.com'), findsOneWidget);
    expect(find.text('メール'), findsOneWidget);
    expect(find.text('ログアウト'), findsOneWidget);
    expect(find.text('アカウントを削除'), findsOneWidget);
    expect(find.text('Linh'), findsNothing);
  });

  testWidgets('ログインしていなければ、ログインへ案内する', (tester) async {
    await tester.pumpWidget(_app(null));

    expect(find.textContaining('ログインしていません'), findsOneWidget);
    expect(find.text('ログイン'), findsOneWidget);
    expect(find.text('ログアウト'), findsNothing);
  });

  testWidgets('アカウント削除はパスワードを聞き、空なら先に進まない', (tester) async {
    await tester.pumpWidget(_app(const AccountInfo(name: 'taro', email: 'taro@example.com', signInMethod: 'メール')));

    await tester.tap(find.text('アカウントを削除'));
    await tester.pumpAndSettle();
    expect(find.text('パスワード'), findsOneWidget);

    await tester.tap(find.text('削除する'));
    await tester.pump();
    expect(find.text('パスワードを入力してください'), findsOneWidget);

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('パスワード'), findsNothing);
  });
}
