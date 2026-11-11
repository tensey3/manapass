import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

// FirebaseAuth
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
  );
});

// 認証状態監視
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

// 認証Controller
final authControllerProvider =
AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  AuthService get _authService => ref.read(authServiceProvider);

  @override
  Future<void> build() async {}

  // 共通処理
  Future<void> _execute(
      Future<void> Function() action,
      ) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(action);
  }

  // ログイン
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _execute(() async {
      await _authService.signIn(
        email: email,
        password: password,
      );
    });
  }

  // 新規登録
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await _execute(() async {
      await _authService.signUp(
        email: email,
        password: password,
      );
    });
  }

  // パスワード再設定
  Future<void> resetPassword(String email) async {
    await _execute(() async {
      await _authService.resetPassword(email);
    });
  }
}