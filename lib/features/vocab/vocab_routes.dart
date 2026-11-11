import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import 'screens/vocab_detail_screen.dart';
import 'screens/word_review_screen.dart';
import 'screens/wordbook_screen.dart';

/// 単語帳の中のページのアドレス。
abstract final class VocabRoutes {
  static const review = '${Routes.vocab}/review';

  static String word(String text) => '${Routes.vocab}/word/${Uri.encodeComponent(text)}';
}

/// 単語帳と、その中のページ。app_router.dart から読み込む。
final vocabRoute = GoRoute(
  path: Routes.vocab,
  builder: (context, state) => const WordbookScreen(),
  routes: [
    GoRoute(path: 'review', builder: (context, state) => const WordReviewScreen()),
    GoRoute(
      path: 'word/:text',
      builder: (context, state) => VocabDetailScreen(text: state.pathParameters['text'] ?? ''),
    ),
  ],
);
