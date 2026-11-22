import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testflutter/data/models/question.dart';
import 'package:testflutter/data/repositories/question_repository.dart';
import 'package:testflutter/features/question/providers/question_list_controller.dart';
import 'package:testflutter/features/question/screens/question_list_screen.dart';
import 'package:testflutter/features/quiz/screens/mock_exam_screen.dart';
import 'package:testflutter/features/quiz/screens/question_answer_screen.dart';
import 'package:testflutter/features/quiz/widgets/question_body.dart';

/// 本物の問題データ（assets/questions）を全部、問題画面に出してみる。
/// 画面からはみ出す・表示できない問題がないかを確かめる。
void main() {
  late List<Question> all;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // テストではネットからフォントを読めないので、プログラムもふつうの字で出す
    codeTextStyle = () => const TextStyle(fontSize: 15, height: 1.6);
    all = await QuestionRepository(null, null, rootBundle).getAllQuestions();
  });

  Future<void> show(WidgetTester tester, Size size, Widget child) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: child)));
    await tester.pump();
  }

  for (final size in const [Size(390, 844), Size(1280, 800)]) {
    testWidgets('全部の問題を出して、答えられる（${size.width.toInt()}×${size.height.toInt()}）', (tester) async {
      expect(all.length, greaterThan(100));
      for (final q in all) {
        await show(tester, size, QuestionAnswerScreen(key: ValueKey(q.id), title: 'テスト', questions: [q]));
        // 画像を読み込ませる
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        await tester.pump();

        // 正解を選んで解答する
        final label = ['ア', 'イ', 'ウ', 'エ', 'オ', 'カ', 'キ', 'ク', 'ケ', 'コ'][q.answerIndex];
        final target = find.text(label).last;
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pump();
        await tester.tap(find.text('解答する'));
        await tester.pump();
        expect(find.text('正解！'), findsOneWidget, reason: '${q.id}');
        expect(tester.takeException(), isNull, reason: '${q.id}');
      }
    });
  }

  testWidgets('ふりがなが出て、点線の単語を押すと意味が出る', (tester) async {
    final q = all.firstWhere((q) => q.id == '2025r07_a_02'); // 浮動小数点形式で表現された…
    await show(tester, const Size(390, 844), QuestionAnswerScreen(title: 'テスト', questions: [q]));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    expect(find.text('ふどう'), findsWidgets); // 浮動 のふりがな
    await tester.tap(find.text('浮動').first);
    // 辞書のファイルを読み込むのを待つ
    for (var i = 0; i < 10 && find.text('floating point').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('浮動小数点'), findsOneWidget); // ポップアップの見出し
    expect(find.text('floating point'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('問題一覧：科目A と 科目B の回が出る', (tester) async {
    await show(
      tester,
      const Size(390, 844),
      ProviderScope(
        overrides: [answerRecordsProvider.overrideWith((ref) async => const <String, AnswerRecord>{})],
        child: const QuestionListScreen(),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('令和8年度 公開問題'), findsOneWidget);
    expect(find.text('0/20'), findsWidgets);
    await tester.tap(find.text('科目B'));
    await tester.pumpAndSettle();
    expect(find.text('科目B・6問'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('模擬試験：答えて提出すると結果が出る', (tester) async {
    final questions = all.where((q) => q.subject == '科目A').take(3).toList();
    await show(
      tester,
      const Size(390, 844),
      MockExamSessionScreen(title: '模擬試験', questions: questions, timeLimit: const Duration(minutes: 5)),
    );
    for (var i = 0; i < questions.length; i++) {
      final label = ['ア', 'イ', 'ウ', 'エ'][questions[i].answerIndex];
      await tester.ensureVisible(find.text(label).last);
      await tester.tap(find.text(label).last);
      await tester.pump();
      await tester.tap(find.text(i < questions.length - 1 ? '次へ' : '提出する'));
      await tester.pump();
    }
    await tester.tap(find.text('提出する').last); // 確認
    await tester.pumpAndSettle();
    expect(find.text('3 / 3 問 正解'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
