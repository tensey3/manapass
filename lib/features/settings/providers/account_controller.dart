import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/auth_controller.dart';
import '../../home/providers/home_controller.dart';
import '../../vocab/providers/wordbook_controller.dart';
import 'exam_goal_controller.dart';

/// アカウント画面に表示する、ログイン中のユーザーの情報。
class AccountInfo {
  const AccountInfo({required this.name, required this.email, required this.signInMethod});

  final String name;
  final String email;
  final String signInMethod; // 例：メール、Google

  /// 名前を登録していないとき（メールで登録した人）は、メールアドレスの @ より前を名前にする。
  factory AccountInfo.fromUser(User user) {
    final email = user.email ?? '';
    final displayName = user.displayName?.trim() ?? '';
    final name = displayName.isNotEmpty ? displayName : (email.contains('@') ? email.split('@').first : email);
    return AccountInfo(
      name: name.isEmpty ? 'ゲスト' : name,
      email: email,
      signInMethod: signInMethodName(user.providerData.map((p) => p.providerId)),
    );
  }
}

/// Firebase のログイン方法の名前を、画面に出す名前にする。
String signInMethodName(Iterable<String> providerIds) {
  const names = {'password': 'メール', 'google.com': 'Google', 'apple.com': 'Apple'};
  final shown = [for (final id in providerIds) names[id] ?? id];
  return shown.isEmpty ? 'ゲスト' : shown.join('・');
}

/// ログイン中のユーザー。ログインしていなければ null。
final accountProvider = Provider<AccountInfo?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull ?? ref.watch(firebaseAuthProvider).currentUser;
  return user == null ? null : AccountInfo.fromUser(user);
});

/// ログアウトする。
Future<void> signOut(WidgetRef ref) async {
  await ref.read(firebaseAuthProvider).signOut();
  _forgetLocalState(ref);
}

/// アカウントを削除する。失敗したときは、画面に出すメッセージを返す（成功したら null）。
///
/// 1. 本人確認のため、パスワードでもう一度ログインする
/// 2. Firestore の解答記録（users/{uid}/questionProgress）を消す
/// 3. 端末に保存した単語帳と試験日・目標を消す
/// 4. Firebase のアカウントを消す
Future<String?> deleteAccount(WidgetRef ref, {required String password}) async {
  final user = ref.read(firebaseAuthProvider).currentUser;
  if (user == null) return 'ログインしていません';

  try {
    final email = user.email;
    final usesPassword = user.providerData.any((p) => p.providerId == 'password');
    if (usesPassword && email != null) {
      await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: email, password: password));
    }
    await _deleteAnswerRecords(FirebaseFirestore.instance, user.uid);
    await _deleteLocalData();
    await user.delete();
  } on FirebaseAuthException catch (e) {
    return _authErrorMessage(e.code);
  } on FirebaseException catch (e) {
    return e.code == 'unavailable' ? '通信できませんでした。インターネット接続を確認してください' : '削除できませんでした（${e.code}）';
  }

  _forgetLocalState(ref);
  return null;
}

/// 解答記録を、まとめて消す（1回に消せる数に上限があるので、少しずつ）。
Future<void> _deleteAnswerRecords(FirebaseFirestore firestore, String uid) async {
  final records = firestore.collection('users').doc(uid).collection('questionProgress');
  while (true) {
    final snapshot = await records.limit(400).get();
    if (snapshot.docs.isEmpty) return;
    final batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

/// 端末に保存した、この人の学習データ（単語帳、試験日と目標）を消す。
/// 見た目などの設定は端末の好みなので残す。
Future<void> _deleteLocalData() async {
  final prefs = await SharedPreferences.getInstance();
  for (final key in prefs.getKeys().toList()) {
    if (key.startsWith('vocab.') || key.startsWith('goal.')) {
      await prefs.remove(key);
    }
  }
}

/// 前の人のデータが画面に残らないように、読み込み直させる。
void _forgetLocalState(WidgetRef ref) {
  ref.invalidate(wordbookProvider);
  ref.invalidate(examGoalProvider);
  ref.invalidate(homeProvider);
}

String _authErrorMessage(String code) => switch (code) {
      'wrong-password' || 'invalid-credential' || 'invalid-login-credentials' => 'パスワードが違います',
      'missing-password' => 'パスワードを入力してください',
      'too-many-requests' => '試した回数が多すぎます。しばらくしてから、もう一度お試しください',
      'network-request-failed' => '通信できませんでした。インターネット接続を確認してください',
      'requires-recent-login' => '安全のため、一度ログアウトして、もう一度ログインしてから削除してください',
      'user-mismatch' || 'user-not-found' => 'アカウントが見つかりません。もう一度ログインしてください',
      _ => '削除できませんでした（$code）',
    };
