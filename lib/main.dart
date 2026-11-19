
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  debugPrint('【確認1】main開始');

  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('【確認2】Flutter初期化完了');

  try {
    debugPrint('【確認3】Firebase初期化開始');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('【確認4】Firebase初期化完了');

    debugPrint('【確認5】日本語の日付設定開始');
    await initializeDateFormatting('ja');
    debugPrint('【確認6】日本語の日付設定完了');

    debugPrint('【確認7】runApp開始');

    runApp(
      const ProviderScope(
        child: App(),
      ),
    );

    debugPrint('【確認8】runApp実行完了');
  } catch (e, stackTrace) {
    debugPrint('【起動エラー】$e');
    debugPrint('$stackTrace');
    rethrow;
  }
}
