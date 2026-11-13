import '../../../data/repositories/question_repository.dart';

/// 復習画面で表示するモデルとデータ取得インターフェース。
class WrongQuestion {
  final String id;
  final String category; // 例: 「テクノロジ系」
  final String text;
  final String userChoice;
  final String correctAnswer;
  final String? explanation;
  const WrongQuestion({
    required this.id,
    required this.category,
    required this.text,
    required this.userChoice,
    required this.correctAnswer,
    this.explanation,
  });
}

class WeakArea {
  final String category;
  final int correct;
  final int total;
  const WeakArea({
    required this.category,
    required this.correct,
    required this.total,
  });
  double get accuracy => total == 0 ? 0 : correct / total;
}

class ReviewData {
  final List<WrongQuestion> wrong;
  final List<WeakArea> weakAreas;
  const ReviewData({required this.wrong, required this.weakAreas});
}

abstract class ReviewDataSource {
  Future<ReviewData> load();
}

class DemoReviewDataSource implements ReviewDataSource {
  const DemoReviewDataSource();
  @override
  Future<ReviewData> load() async => const ReviewData(
    weakAreas: [
      WeakArea(category: 'ネットワーク', correct: 2, total: 8),
      WeakArea(category: 'データベース', correct: 4, total: 9),
      WeakArea(category: 'セキュリティ', correct: 5, total: 10),
    ],
    wrong: [
      WrongQuestion(
        id: 'q1',
        category: 'ネットワーク',
        text: 'TCP/IPの階層で、IPアドレスによる経路選択を行うのはどれか。',
        userChoice: 'トランスポート層',
        correctAnswer: 'インターネット層',
        explanation: 'IPアドレスで宛先を判断して経路を選ぶのはインターネット層（ネットワーク層）です。',
      ),
      WrongQuestion(
        id: 'q2',
        category: 'データベース',
        text: '正規化の目的として適切なものはどれか。',
        userChoice: '検索速度の向上',
        correctAnswer: 'データの重複と矛盾の排除',
        explanation: '正規化はデータの冗長性を減らし、更新時の矛盾を防ぎます。',
      ),
    ],
  );
}

class FirestoreReviewDataSource implements ReviewDataSource {
  const FirestoreReviewDataSource(this._questionRepository);

  final QuestionRepository _questionRepository;

  @override
  Future<ReviewData> load() async {
    final entries = await _questionRepository.fetchQuestionsToReview();
    return ReviewData(
      weakAreas: const [],
      wrong: [
        for (final entry in entries)
          WrongQuestion(
            id: entry.question.id,
            category: '${entry.question.category}・${entry.question.topic}',
            text: entry.question.text,
            userChoice: entry.question.choices[entry.lastWrongAnswerIndex],
            correctAnswer: entry.question.choices[entry.question.answerIndex],
            explanation: entry.question.explanation,
          ),
      ],
    );
  }
}
