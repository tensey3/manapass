import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 認証画面
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/email_login_screen.dart';
import '../../features/auth/screens/account_create_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';

// その他の画面
import '../../features/home/screens/home_screen.dart';
import '../../features/question/screens/question_list_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/review/screens/review_screen.dart';
import '../../features/settings/settings_routes.dart';
import '../../features/vocab/vocab_routes.dart'; // ← vocabRoute を使うためにインポート
import '../../features/question/screens/random_quiz_screen.dart';
import '../../features/question/screens/mock_exam_screen.dart';
import '../../features/question/screens/photo_add_screen.dart';
import '../../data/repositories/question_repository.dart';
import '../../features/review/providers/review_data_source.dart';
import '../shell/app_shell.dart';
import 'routes.dart';

// 準備中のルート（現在未実装のものがあればここに追加）
const _pendingRoutes = [
  // Routes.review は vocab_routes.dart 内で定義されたため削除しました
];

final appRouter = GoRouter(
  initialLocation: Routes.signIn,

  routes: [
    // 認証画面（サイドメニューなし）
    GoRoute(
      path: Routes.signIn,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: Routes.emailLogin,
      builder: (context, state) => const EmailLoginScreen(),
    ),
    GoRoute(
      path: Routes.accountCreate,
      builder: (context, state) => const AccountCreateScreen(),
    ),
    GoRoute(
      path: Routes.resetPassword,
      builder: (context, state) => const ResetPasswordScreen(),
    ),

    // メイン画面（サイドメニューあり）
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
          path: Routes.review,
          builder: (context, state) => Consumer(
            builder: (context, ref, _) => ReviewScreen(
              dataSource: FirestoreReviewDataSource(
                ref.watch(questionRepositoryProvider),
              ),
              onRetryAll: (ids) {
                context.push(Routes.randomQuiz, extra: ids);
              },
              onRetryOne: (id) {
                context.push(Routes.randomQuiz, extra: [id]);
              },
            ),
          ),
        ),
        GoRoute(
          path: Routes.progress,
          builder: (context, state) => const ProgressScreen(),
        ),
        GoRoute(
          path: Routes.randomQuiz,
          builder: (context, state) {
            final extra = state.extra;
            return RandomQuizScreen(
              questionIds: extra is List<String> ? extra : null,
            );
          },
        ),
        GoRoute(
          path: Routes.mockExam,
          builder: (context, state) => const MockExamScreen(),
        ),
        GoRoute(
          path: Routes.addFromPhoto,
          builder: (context, state) => const AddFromPhotoScreen(),
        ),

        // 単語帳画面（子ルートの review や word/:text も含まれます）
        vocabRoute,

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
