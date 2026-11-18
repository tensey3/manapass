import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/features/progress/data/progress_models.dart';
import 'package:testflutter/features/progress/data/progress_source.dart';
import 'package:testflutter/features/progress/providers/progress_controller.dart';
import 'package:testflutter/features/progress/screens/progress_screen.dart';
import 'package:testflutter/features/progress/widgets/stat_tile.dart';

class _FakeSource implements ProgressSource {
  _FakeSource(this.load_);

  final Future<ProgressData?> Function() load_;

  @override
  Future<ProgressData?> load() => load_();
}

Widget _app(Future<ProgressData?> Function() load) => ProviderScope(
      overrides: [progressSourceProvider.overrideWithValue(_FakeSource(load))],
      child: const MaterialApp(home: Scaffold(body: ProgressScreen())),
    );

const _topics = ['データベース', 'ネットワーク', 'アルゴリズム'];

// 2026-11-18 は水曜日
final _wednesday = DateTime(2026, 11, 18, 10);

void main() {
  group('AnswerRecord.fromFirestore', () {
    test('解いた回数と間違えた回数から、正解した回数を出す', () {
      final r = AnswerRecord.fromFirestore(
        {'attempts': 3, 'wrongCount': 1, 'needsReview': false, 'lastAnsweredCorrectly': true},
        topic: 'データベース',
      )!;
      expect(r.attempts, 3);
      expect(r.correct, 2);
      expect(r.needsReview, isFalse);
      expect(r.topic, 'データベース');
    });

    test('needsReview がなければ、最後に間違えたかで決める', () {
      final r = AnswerRecord.fromFirestore({'attempts': 1, 'lastAnsweredCorrectly': false}, topic: 'x')!;
      expect(r.needsReview, isTrue);
      expect(r.correct, 1); // wrongCount がないので 0 回間違い扱い
    });

    test('一度も解いていない・形のおかしい記録は使わない', () {
      expect(AnswerRecord.fromFirestore({}, topic: 'x'), isNull);
      expect(AnswerRecord.fromFirestore({'attempts': 0}, topic: 'x'), isNull);
      expect(AnswerRecord.fromFirestore({'attempts': '2'}, topic: 'x'), isNull);
    });

    test('間違えた回数が解いた回数より多くても、正解がマイナスにならない', () {
      final r = AnswerRecord.fromFirestore({'attempts': 2, 'wrongCount': 5}, topic: 'x')!;
      expect(r.correct, 0);
    });
  });

  group('buildProgress', () {
    test('記録から数字を計算する', () {
      final state = buildProgress(
        answers: const [
          AnswerRecord(topic: 'データベース', attempts: 2, correct: 2, needsReview: false),
          AnswerRecord(topic: 'データベース', attempts: 2, correct: 1, needsReview: true),
          AnswerRecord(topic: 'ネットワーク', attempts: 1, correct: 0, needsReview: true),
        ],
        topics: _topics,
        now: _wednesday,
      );
      expect(state.accuracyPercent, 60); // 3 / 5
      expect(state.questionsDone, 3);
      expect(state.toReview, 2);
      expect(state.todayIndex, 2);
      expect(
        [for (final s in state.subjects) (s.name, s.percent)],
        [('データベース', 75), ('ネットワーク', 0), ('アルゴリズム', null)],
      );
    });

    test('まだ1問も解いていなければ、正答率はなし（0% にしない）', () {
      final state = buildProgress(answers: const [], topics: _topics, now: _wednesday);
      expect(state.accuracyPercent, isNull);
      expect(state.questionsDone, 0);
      expect(state.subjects.every((s) => s.percent == null), isTrue);
    });

    test('学習時間の記録がなければ、グラフも合計もなし', () {
      final state = buildProgress(answers: const [], topics: _topics, now: _wednesday);
      expect(state.weekMinutes, isNull);
      expect(state.weekTotalMinutes, isNull);
    });

    test('学習時間があれば、今日より後の日は出さない', () {
      final state = buildProgress(
        answers: const [],
        topics: _topics,
        studyMinutes: const [10, 20, 30, 40, 50, 60, 70],
        now: _wednesday,
      );
      expect(state.weekMinutes, [10, 20, 30, null, null, null, null]);
      expect(state.weekTotalMinutes, 60);
    });

    test('記録にしかない分野も表示する', () {
      final state = buildProgress(
        answers: const [AnswerRecord(topic: '基礎理論', attempts: 1, correct: 1, needsReview: false)],
        topics: _topics,
        now: _wednesday,
      );
      expect(state.subjects.last.name, '基礎理論');
      expect(state.subjects.last.percent, 100);
    });

    test('模擬試験は新しい順', () {
      final state = buildProgress(
        answers: const [],
        topics: const [],
        mockResults: [
          MockResult(date: DateTime(2026, 10, 1), subject: 'A', correct: 6, total: 10, time: Duration.zero),
          MockResult(date: DateTime(2026, 11, 1), subject: 'B', correct: 3, total: 6, time: Duration.zero),
        ],
        now: _wednesday,
      );
      expect(state.mockResults.first.subject, 'B');
    });
  });

  group('進捗画面', () {
    testWidgets('記録を表示する', (tester) async {
      await tester.pumpWidget(_app(() async => const ProgressData(
            topics: _topics,
            answers: [
              AnswerRecord(topic: 'データベース', attempts: 4, correct: 3, needsReview: false),
              AnswerRecord(topic: 'ネットワーク', attempts: 1, correct: 0, needsReview: true),
            ],
          )));
      await tester.pumpAndSettle();

      expect(find.text('60%'), findsOneWidget); // 正答率 3 / 5
      expect(find.text('2'), findsOneWidget); // 解いた問題
      expect(find.text('1'), findsOneWidget); // 復習が必要
      expect(find.text('75%'), findsOneWidget); // データベース
      expect(find.text('まだ解いていません'), findsOneWidget); // アルゴリズム
      expect(find.textContaining('学習時間はまだ記録されていません'), findsOneWidget);
      expect(find.text('まだ模擬試験の記録がありません'), findsOneWidget);
      expect(find.textContaining('まだ問題を解いていません'), findsNothing);
    });

    testWidgets('まだ解いていなければ、ランダム出題へ案内する', (tester) async {
      await tester.pumpWidget(_app(() async => const ProgressData(topics: _topics, answers: [])));
      await tester.pumpAndSettle();

      expect(find.textContaining('まだ問題を解いていません'), findsOneWidget);
      expect(find.text('ランダム出題へ'), findsOneWidget);
      // 上の数字のうち、正答率と学習時間は「—」（0% にしない）
      expect(find.descendant(of: find.byType(StatTile), matching: find.text('—')), findsNWidgets(2));
      expect(find.text('0%'), findsNothing);
    });

    testWidgets('ログインしていなければ、ログインへ案内する', (tester) async {
      await tester.pumpWidget(_app(() async => null));
      await tester.pumpAndSettle();

      expect(find.text('ログインすると、進捗が表示されます。'), findsOneWidget);
      expect(find.text('正答率'), findsNothing);
    });

    testWidgets('読み込めなければ、再読み込みできる', (tester) async {
      var calls = 0;
      await tester.pumpWidget(_app(() async {
        calls++;
        if (calls == 1) throw Exception('offline');
        return const ProgressData(topics: _topics, answers: []);
      }));
      await tester.pumpAndSettle();
      expect(find.textContaining('進捗を読み込めませんでした'), findsOneWidget);

      await tester.tap(find.text('再読み込み'));
      await tester.pumpAndSettle();
      expect(find.textContaining('進捗を読み込めませんでした'), findsNothing);
      expect(find.text('正答率'), findsOneWidget);
      expect(calls, 2);
    });
  });
}
