import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/question/screens/question_list_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/review/screens/review_screen.dart'; // ① 復習画面をインポート（※パスは実際の配置に合わせて調整してください）
import '../shell/app_shell.dart';
import 'routes.dart';

const _pendingRoutes = [
  // Routes.question, // 問題は解除済み
  // Routes.review,   // ② ここから「復習」を外す
  Routes.vocab,
  // Routes.progress, // 進捗はすでに外れている
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
        GoRoute(
          path: Routes.progress,
          builder: (context, state) => const ProgressScreen(),
        ),
        // ③ 「復習」の個別ルートを追加
        GoRoute(
          path: Routes.review,
          builder: (context, state) => const ReviewScreen(),
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