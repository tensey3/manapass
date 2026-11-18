// 進捗画面で使うデータの形。

/// 1問ごとの解答の記録（Firestore の users/{uid}/questionProgress/{問題ID} 1件分）。
class AnswerRecord {
  const AnswerRecord({required this.topic, required this.attempts, required this.correct, required this.needsReview});

  final String topic; // 分野（問題の topic）
  final int attempts; // 解いた回数
  final int correct; // 正解した回数
  final bool needsReview; // 最後に間違えた = 復習が必要

  /// Firestore の記録から作る。[topic] はその問題の分野。
  /// 一度も解いていない記録や、形のおかしい記録は null。
  static AnswerRecord? fromFirestore(Map<String, dynamic> data, {required String topic}) {
    final attempts = data['attempts'];
    if (attempts is! int || attempts <= 0) return null;
    final wrong = data['wrongCount'];
    final wrongCount = wrong is int ? wrong.clamp(0, attempts) : 0;
    final needsReview = data['needsReview'];
    return AnswerRecord(
      topic: topic,
      attempts: attempts,
      correct: attempts - wrongCount,
      needsReview: needsReview is bool ? needsReview : data['lastAnsweredCorrectly'] == false,
    );
  }
}

/// 模擬試験の結果1回分。
/// 模擬試験はまだ結果を保存していないので、今は記録が空。
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
