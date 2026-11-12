import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:testflutter/app/router/routes.dart';
import 'package:testflutter/features/auth/providers/auth_controller.dart';
import 'package:testflutter/features/auth/screens/email_login_screen.dart';

void main() {
  testWidgets('successful login navigates to the home screen', (tester) async {
    final router = GoRouter(
      initialLocation: Routes.emailLogin,
      routes: [
        GoRoute(
          path: Routes.emailLogin,
          builder: (context, state) => const EmailLoginScreen(),
        ),
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const Scaffold(body: Text('ホーム画面')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(FakeAuthController.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'ログイン'));
    await tester.pumpAndSettle();

    expect(find.text('ホーム画面'), findsOneWidget);
  });
}

class FakeAuthController extends AuthController {
  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}
}
