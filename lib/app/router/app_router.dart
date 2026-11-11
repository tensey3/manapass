import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/question/screens/question_list_screen.dart';
import '../../features/question/screens/random_quiz_screen.dart'; // ← ランダムクイズ画面のインポートを追加
import '../../features/question/screens/mock_exam_screen.dart';
import '../../features/question/screens/photo_add_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/settings/settings_routes.dart';
import '../../features/vocab/vocab_routes.dart';
import '../shell/app_shell.dart';
import 'routes.dart';

const _pendingRoutes = [
  // Routes.question, // 問題は解除済み
  Routes.review, // 復習画面は未実装のため準備中
  // Routes.vocab, // 単語帳は vocabRoute で追加
  // Routes.progress, // 進捗は下で追加
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
          path: Routes.randomQuiz, // ← ランダムクイズ画面のルートを追加
          builder: (context, state) => const RandomQuizScreen(),
        ),
        GoRoute(
          path: Routes.mockExam, // ← ② この GoRoute を追加！
          builder: (context, state) => const MockExamScreen(),
        ),
        GoRoute(
          path: Routes.addFromPhoto,
          builder: (context, state) => const AddFromPhotoScreen(), // ← 正しいクラス名に直す
        ),
        GoRoute(
          path: Routes.progress,
          builder: (context, state) => const ProgressScreen(),
        ),
        settingsRoute,
        vocabRoute,
        for (final path in _pendingRoutes)
          GoRoute(
            path: path,
            builder: (context, state) => const Center(child: Text('準備中')),
          ),
      ],
    ),
  ],
);
