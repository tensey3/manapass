import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/settings/data/theme_options.dart';
import '../features/settings/providers/settings_controller.dart';
import 'router/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 設定画面（見た目）で選んだフォントを、アプリ全体に使う
    final font = ref.watch(settingsProvider.select((s) => s.valueOrNull?.font));
    final theme = AppTheme.light;

    return MaterialApp.router(
      title: 'まなパス',
      debugShowCheckedModeBanner: false,
      theme: font == null ? theme : theme.copyWith(textTheme: fontTextTheme(font, theme.textTheme)),
      routerConfig: appRouter,
    );
  }
}
