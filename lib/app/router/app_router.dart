import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/question/screens/question_list_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/settings/settings_routes.dart';
import '../shell/app_shell.dart';
import 'routes.dart';

const _pendingRoutes = [
  // Routes.question, // 問題は解除済み
  Routes.review, // 復習画面は未実装のため準備中
  Routes.vocab,
  // Routes.progress, // 進捗はすでに外れている
  // Routes.settings, // 設定は settingsRoute で追加
];

final appRouter = GoRouter(
  initialLocation: Routes.home,
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.matchedLocation, child: child),
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: Routes.question,
          builder: (context, state) => const QuestionListScreen(),
        ),
        GoRoute(
          path: Routes.progress,
          builder: (context, state) => const ProgressScreen(),
        ),
        settingsRoute,
        for (final path in _pendingRoutes)
          GoRoute(
            path: path,
            builder: (context, state) => const Center(child: Text('準備中')),
          ),
      ],
    ),
  ],
);