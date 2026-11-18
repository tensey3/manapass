import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/data/models/question.dart';

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

    test('本物の過去問データ：正解の選択肢の記号が、answer と一致する', () {
      final files = Directory('assets/questions')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'));
      var checked = 0;
      for (final file in files) {
        final list = jsonDecode(file.readAsStringSync()) as List;
        for (final raw in list.cast<Map<String, dynamic>>()) {
          final q = Question.fromMap(raw);
          expect(q.answerIndex, inInclusiveRange(0, q.choices.length - 1), reason: '${raw['id']}');
          final answer = raw['answer'];
          if (answer is String) {
            expect(q.choices[q.answerIndex].trim().startsWith(answer.trim()), isTrue,
                reason: '${raw['id']}: 正解 $answer → ${q.choices[q.answerIndex]}');
            checked++;
          }
        }
      }
      expect(checked, greaterThan(0));
    });
  });
}
