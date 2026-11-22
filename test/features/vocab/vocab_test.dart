import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testflutter/data/models/question.dart';
import 'package:testflutter/features/vocab/data/vocab_data.dart';
import 'package:testflutter/features/vocab/providers/dictionary_controller.dart';
import 'package:testflutter/features/vocab/providers/lookup_controller.dart';
import 'package:testflutter/features/vocab/providers/related_questions_controller.dart';
import 'package:testflutter/features/vocab/screens/vocab_detail_screen.dart';
import 'package:testflutter/features/vocab/screens/wordbook_screen.dart';

Question _q(String id, String text, {int? year, List<String> choices = const [], String topic = ''}) =>
    Question(id: id, year: year, subject: '科目A', topic: topic, question: text, choices: choices);

final _questions = [
  _q('2023_a_q05', 'トランザクションの排他制御について…', year: 2023),
  _q('2025_a_q03', 'データベースの障害回復で…', year: 2025, choices: ['ア 排他制御を行う', 'イ ログを取る']),
  _q('2024_a_q10', 'ネットワークの問題', year: 2024),
];

Widget _app(Widget child, {List<Question>? questions}) => ProviderScope(
      overrides: [
        vocabQuestionsProvider.overrideWith((ref) async => questions ?? _questions),
        // 辞書のファイルは読まずに、用語集だけで確かめる
        dictionaryProvider.overrideWith((ref) async => glossary),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('出てくる問題', () {
    test('問題文か選択肢に単語がある問題を、新しい年度から', () {
      final found = questionsContaining(_questions, '排他制御');
      expect(found.map((q) => q.id), ['2025_a_q03', '2023_a_q05']);
      expect(questionsContaining(_questions, 'セキュリティ'), isEmpty);
      expect(questionsContaining(_questions, ' '), isEmpty);
    });

    test('出典の表示', () {
      expect(questionSourceLabel(_q('2025_a_q03', 'x', year: 2025)), '2025年度・科目A・問3');
      expect(questionSourceLabel(_q('2024_a_q12', 'x', year: 2024, topic: 'データベース')), '2024年度・科目A・問12・データベース');
      expect(questionSourceLabel(_q('fe-basic-dns-001', 'x', topic: 'ネットワーク')), '科目A・ネットワーク');
    });
  });

  group('英語を少しずつ減らす', () {
    test('設定がオンで、3回以上調べた単語だけ隠す', () {
      expect(shouldHideEnglish(reduceEnglish: true, lookups: 3), isTrue);
      expect(shouldHideEnglish(reduceEnglish: true, lookups: 2), isFalse);
      expect(shouldHideEnglish(reduceEnglish: false, lookups: 10), isFalse);
    });

    test('調べた回数を数えて、端末に保存する', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final counts = container.read(lookupCountsProvider.notifier);
      await container.read(lookupCountsProvider.future);
      await counts.record('索引');
      await counts.record('索引');
      expect(container.read(lookupCountsProvider).value, {'索引': 2});

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('vocab.lookups'), '{"索引":2}');
    });
  });

  group('単語の詳細', () {
    testWidgets('Firestore の問題から、出てくる問題を表示する', (tester) async {
      await tester.pumpWidget(_app(const VocabDetailScreen(text: '排他制御')));
      await tester.pumpAndSettle();

      expect(find.text('2025年度・科目A・問3'), findsOneWidget);
      expect(find.text('2023年度・科目A・問5'), findsOneWidget);
      expect(find.text('ア 排他制御を行う'), findsNothing); // 閉じているときは選択肢を出さない

      await tester.tap(find.text('2025年度・科目A・問3'));
      await tester.pumpAndSettle();
      expect(find.text('ア 排他制御を行う', findRichText: true), findsOneWidget);
    });

    testWidgets('出てくる問題がなければ、そう表示する', (tester) async {
      await tester.pumpWidget(_app(const VocabDetailScreen(text: '排他制御'), questions: const []));
      await tester.pumpAndSettle();
      expect(find.text('この単語が出てくる問題は、まだありません'), findsOneWidget);
    });

    testWidgets('多いときは5問まで出して、残りはボタンで', (tester) async {
      final many = [for (var i = 1; i <= 8; i++) _q('2025_a_q$i', '排他制御 その$i', year: 2025)];
      await tester.pumpWidget(_app(const VocabDetailScreen(text: '排他制御'), questions: many));
      await tester.pumpAndSettle();
      expect(find.text('ほかに3問を見る'), findsOneWidget);
    });

    testWidgets('開くと、調べた回数が増える', (tester) async {
      await tester.pumpWidget(_app(const VocabDetailScreen(text: '排他制御')));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('vocab.lookups'), '{"排他制御":1}');
    });

    testWidgets('3回調べた単語は、設定がオンなら英語を隠す（押すと見える）', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vocab.lookups': '{"排他制御":3}',
        'settings.reduceEnglish': true,
      });
      await tester.pumpWidget(_app(const VocabDetailScreen(text: '排他制御')));
      await tester.pumpAndSettle();

      expect(find.text('タップして英語を見る'), findsOneWidget);
      expect(find.textContaining('exclusive control'), findsNothing);

      await tester.tap(find.text('タップして英語を見る'));
      await tester.pumpAndSettle();
      expect(find.textContaining('exclusive control'), findsOneWidget);
    });

    testWidgets('ふりがながオフなら、読みを出さない', (tester) async {
      SharedPreferences.setMockInitialValues({'settings.furigana': false});
      await tester.pumpWidget(_app(const VocabDetailScreen(text: '排他制御')));
      await tester.pumpAndSettle();
      expect(find.text('はいたせいぎょ'), findsNothing);
      expect(find.text('排他制御'), findsOneWidget);
    });

    testWidgets('ふりがながオンなら、読みを出す', (tester) async {
      await tester.pumpWidget(_app(const VocabDetailScreen(text: '排他制御')));
      await tester.pumpAndSettle();
      expect(find.text('はいたせいぎょ'), findsOneWidget);
    });
  });

  group('単語帳', () {
    testWidgets('検索すると、単語帳にない辞書の単語も出る', (tester) async {
      await tester.pumpWidget(_app(const WordbookScreen()));
      await tester.pumpAndSettle();
      expect(find.text('ガントチャート'), findsNothing);

      await tester.enterText(find.byType(TextField), 'ガント');
      await tester.pumpAndSettle();
      expect(find.text('ガントチャート'), findsOneWidget);
      expect(find.textContaining('辞書から'), findsOneWidget);
    });

    testWidgets('単語帳が空でも、検索できる', (tester) async {
      SharedPreferences.setMockInitialValues({'vocab.savedWords': <String>[]});
      await tester.pumpWidget(_app(const WordbookScreen()));
      await tester.pumpAndSettle();
      expect(find.text('まだ単語がありません'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'DNS');
      await tester.pumpAndSettle();
      expect(find.text('DNS'), findsWidgets);
      expect(find.text('まだ単語がありません'), findsNothing);
    });
  });
}
