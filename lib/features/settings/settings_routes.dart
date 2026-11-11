import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import 'screens/account_screen.dart';
import 'screens/appearance_screen.dart';
import 'screens/exam_goal_screen.dart';
import 'screens/furigana_screen.dart';
import 'screens/legal_screen.dart';
import 'screens/license_screen.dart';
import 'screens/settings_screen.dart';

/// 設定の中のページのアドレス。
abstract final class SettingsRoutes {
  static const examGoal = '${Routes.settings}/exam-goal';
  static const furigana = '${Routes.settings}/furigana';
  static const appearance = '${Routes.settings}/appearance';
  static const account = '${Routes.settings}/account';
  static const terms = '${Routes.settings}/terms';
  static const privacy = '${Routes.settings}/privacy';
  static const licenses = '${Routes.settings}/licenses';
}

/// 設定画面と、その中のページ。app_router.dart から読み込む。
final settingsRoute = GoRoute(
  path: Routes.settings,
  builder: (context, state) => const SettingsScreen(),
  routes: [
    GoRoute(path: 'exam-goal', builder: (context, state) => const ExamGoalScreen()),
    GoRoute(path: 'furigana', builder: (context, state) => const FuriganaScreen()),
    GoRoute(path: 'appearance', builder: (context, state) => const AppearanceScreen()),
    GoRoute(path: 'account', builder: (context, state) => const AccountScreen()),
    GoRoute(path: 'terms', builder: (context, state) => const LegalScreen(doc: LegalDoc.terms)),
    GoRoute(path: 'privacy', builder: (context, state) => const LegalScreen(doc: LegalDoc.privacy)),
    GoRoute(path: 'licenses', builder: (context, state) => const LicenseScreen()),
  ],
);
