import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/data/models/question.dart';

void main() {
  const data = {
    'exam': '基本情報技術者試験',
    'category': 'テクノロジ系',
    'topic': 'データベース',
    'question': '正規化の目的はどれか。',
    'choices': ['A', 'B', 'C', 'D'],
    'answerIndex': 1,
    'explanation': '重複を減らし不整合を防ぎます。',
  };

  test('parses a Firestore question document', () {
    final question = Question.fromFirestore('question-1', data);

    expect(question.id, 'question-1');
    expect(question.text, '正規化の目的はどれか。');
    expect(question.choices, ['A', 'B', 'C', 'D']);
    expect(question.answerIndex, 1);
  });

  test('rejects an answer index outside the choices', () {
    expect(
      () => Question.fromFirestore('question-1', {...data, 'answerIndex': 4}),
      throwsFormatException,
    );
  });
}
