import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/data/models/question.dart';

void main() {
  // 新しい Question モデルのマップ構造（データベースのカラム名）に合わせたテストデータ
  final data = {
    'id': 1,
    'year': 2026,
    'subject': '科目A',
    'category': 'テクノロジ系',
    'question_text': '正規化の目的はどれか。',
    'options': 'A|||B|||C|||D',
    'correct_index': 1,
    'explanation': '重複を減らし不整合を防ぎます。',
  };

  test('parses a question map correctly', () {
    final question = Question.fromMap(data);

    expect(question.id, 1);
    expect(question.questionText, '正規化の目的はどれか。');
    expect(question.options, ['A', 'B', 'C', 'D']);
    expect(question.correctIndex, 1);
  });

  test('converts question back to map correctly', () {
    final question = Question(
      id: 1,
      year: 2026,
      subject: '科目A',
      category: 'テクノロジ系',
      questionText: '正規化の目的はどれか。',
      options: ['A', 'B', 'C', 'D'],
      correctIndex: 1,
      explanation: '重複を減らし不整合を防ぎます。',
    );

    final map = question.toMap();

    expect(map['id'], 1);
    expect(map['year'], 2026);
    expect(map['subject'], '科目A');
    expect(map['category'], 'テクノロジ系');
    expect(map['question_text'], '正規化の目的はどれか。');
    expect(map['options'], 'A|||B|||C|||D');
    expect(map['correct_index'], 1);
    expect(map['explanation'], '重複を減らし不整合を防ぎます。');
  });
}