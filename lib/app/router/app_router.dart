import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/question/screens/question_list_screen.dart';
import '../../features/progress/screens/progress_screen.dart'; // ① 進捗画面をインポート（パスは実際の構成に合わせてください）
import '../shell/app_shell.dart';
import 'routes.dart';

const _pendingRoutes = [
  // Routes.question, // 問題は解除済み
  Routes.review,
  Routes.vocab,
  // Routes.progress, // ② ここから「進捗」を外す
  Routes.settings,
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
        // ③ 「進捗」の個別ルートを追加
        GoRoute(
          path: Routes.progress,
          builder: (context, state) => const ProgressScreen(),
        ),
        for (final path in _pendingRoutes)
          GoRoute(
            path: path,
            builder: (context, state) => const Center(child: Text('準備中')),
          ),
      ],
    ),
  ],
);