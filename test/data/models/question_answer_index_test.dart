import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/data/models/question.dart';
import 'package:testflutter/features/vocab/data/vocab_data.dart';

void main() {
  group('正解の番号', () {
    test('記号（ア〜エ）で書かれた正解を番号にする', () {
      expect(Question.fromMap({'answer': 'ア'}).answerIndex, 0);
      expect(Question.fromMap({'answer': 'イ'}).answerIndex, 1);
      expect(Question.fromMap({'answer': 'ウ'}).answerIndex, 2);
      expect(Question.fromMap({'answer': ' エ '}).answerIndex, 3);
    });

    test('番号で書かれていれば、そのまま使う', () {
      expect(Question.fromMap({'answerIndex': 2}).answerIndex, 2);
      expect(Question.fromMap({'correct_index': 1}).answerIndex, 1);
      expect(Question.fromMap({'answerIndex': 1, 'answer': 'エ'}).answerIndex, 1);
    });

    test('読めないときだけ 0', () {
      expect(Question.fromMap({}).answerIndex, 0);
      expect(Question.fromMap({'answer': '?'}).answerIndex, 0);
    });

  });

  group('アプリに入っている問題データ（assets/questions）', () {
    final index = jsonDecode(File('assets/questions/index.json').readAsStringSync()) as Map<String, dynamic>;
    final exams = (index['exams'] as List).cast<Map<String, dynamic>>();

    test('一覧にある試験のファイルが全部あり、問題数が一覧と同じ', () {
      expect(exams, isNotEmpty);
      for (final exam in exams) {
        final list = jsonDecode(File('assets/questions/${exam['file']}').readAsStringSync()) as List;
        expect(list.length, exam['count'], reason: '${exam['id']}');
      }
    });

    test('どの問題も、正解が解答群の中にあり、ID が重ならず、出典がある', () {
      final ids = <String>{};
      var count = 0;
      for (final exam in exams) {
        final list = jsonDecode(File('assets/questions/${exam['file']}').readAsStringSync()) as List;
        for (final raw in list.cast<Map<String, dynamic>>()) {
          final q = Question.fromMap(raw);
          final id = q.id.toString();
          expect(ids.add(id), isTrue, reason: '$id が重なっている');
          expect(q.exam, exam['id'], reason: id);
          expect(q.subject, exam['subject'], reason: id);
          expect(q.answerIndex, inInclusiveRange(0, q.choices.length - 1), reason: id);
          expect(q.source, startsWith('出典：'), reason: id);
          expect(q.blocks, isNotEmpty, reason: id);
          // 解答群が画像でなければ、選択肢の文字が全部ある
          if (q.choicesImage == null) {
            expect(q.choices.every((c) => c.trim().isNotEmpty), isTrue, reason: id);
          }
          count++;
        }
      }
      expect(count, greaterThan(100));
    });

    test('ふりがなの単語をつなげると元の文と同じで、押せる単語は全部意味がある', () {
      final dict = jsonDecode(File('assets/dict/words.json').readAsStringSync()) as Map<String, dynamic>;
      var tokens = 0;
      var links = 0;
      for (final exam in exams) {
        final list = jsonDecode(File('assets/questions/${exam['file']}').readAsStringSync()) as List;
        for (final raw in list.cast<Map<String, dynamic>>()) {
          final q = Question.fromMap(raw);
          void check(List<RubyToken> ruby, String text) {
            if (ruby.isEmpty) return;
            expect(ruby.map((t) => t.text).join(), text, reason: '${q.id}: ふりがなで文字が変わった');
            for (final t in ruby) {
              tokens++;
              if (t.parts != null) {
                expect(t.parts!.map((p) => p.$1).join(), t.text, reason: '${q.id}: ${t.text}');
              }
              if (t.key != null) {
                links++;
                expect(dict.containsKey(t.key) || glossary.containsKey(t.key), isTrue,
                    reason: '${q.id}: ${t.key} の意味がない');
              }
            }
          }

          for (final b in q.blocks) {
            check(b.ruby, b.text);
          }
          for (var i = 0; i < q.choicesRuby.length; i++) {
            check(q.choicesRuby[i], q.choices[i]);
          }
        }
      }
      expect(tokens, greaterThan(1000));
      expect(links, greaterThan(1000));
    });

    test('問題の図・解答群の画像が全部ある', () {
      for (final exam in exams) {
        final list = jsonDecode(File('assets/questions/${exam['file']}').readAsStringSync()) as List;
        for (final raw in list.cast<Map<String, dynamic>>()) {
          final q = Question.fromMap(raw);
          final paths = [
            for (final b in q.blocks)
              if (b.isImage) b.assetPath!,
            if (q.choicesImagePath != null) q.choicesImagePath!,
          ];
          for (final p in paths) {
            expect(File(p).existsSync(), isTrue, reason: '${q.id}: $p がない');
          }
        }
      }
    });
  });
}
