// 進捗画面で使う見本のデータ。
// あとで：解答の記録・学習時間・模擬試験の結果は、問題や模擬試験の機能が保存したデータに置き換える。

/// 進捗に表示する分野（この順番で表示する）。
const progressSubjects = ['ネットワーク', 'アルゴリズム', '基礎理論', 'データベース', 'セキュリティ', 'マネジメント'];

/// 1問ごとの解答の記録。
class AnswerRecord {
  const AnswerRecord({required this.topic, required this.attempts, required this.correct, required this.lastCorrect});

  final String topic; // 分野
  final int attempts; // 解いた回数
  final int correct; // 正解した回数
  final bool lastCorrect; // false = 復習が必要
}

/// 模擬試験の結果1回分。
class MockResult {
  const MockResult({
    required this.date,
    required this.subject,
    required this.correct,
    required this.total,
    required this.time,
  });

  final DateTime date;
  final String subject; // 'A' または 'B'（科目A / 科目B）
  final int correct;
  final int total;
  final Duration time; // かかった時間

  int get percent => total == 0 ? 0 : (correct * 100 / total).round();

  /// 合格の目安（基本情報技術者試験は 1000点中600点 = 60%）。
  bool get passed => percent >= 60;
}

const sampleAnswers = [
  AnswerRecord(topic: 'データベース', attempts: 2, correct: 2, lastCorrect: true),
  AnswerRecord(topic: 'ネットワーク', attempts: 2, correct: 0, lastCorrect: false),
  AnswerRecord(topic: 'セキュリティ', attempts: 1, correct: 1, lastCorrect: true),
  AnswerRecord(topic: '基礎理論', attempts: 3, correct: 2, lastCorrect: true),
  AnswerRecord(topic: 'アルゴリズム', attempts: 1, correct: 0, lastCorrect: false),
  AnswerRecord(topic: 'セキュリティ', attempts: 1, correct: 1, lastCorrect: true),
  AnswerRecord(topic: 'データベース', attempts: 2, correct: 1, lastCorrect: false),
];

/// 今週、毎日勉強した時間（分）。月曜日〜日曜日。
const sampleStudyMinutes = [40, 25, 55, 0, 30, 70, 20];

final sampleMockResults = [
  MockResult(date: DateTime(2026, 10, 5, 13, 59), subject: 'A', correct: 6, total: 10, time: const Duration(minutes: 13, seconds: 20)),
  MockResult(date: DateTime(2026, 10, 10, 12, 59), subject: 'A', correct: 7, total: 10, time: const Duration(minutes: 12, seconds: 5)),
  MockResult(date: DateTime(2026, 11, 8, 10, 30), subject: 'B', correct: 2, total: 6, time: const Duration(minutes: 31, seconds: 40)),
];
