class Question {
  const Question({
    required this.id,
    required this.exam,
    required this.category,
    required this.topic,
    required this.text,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
  });

  final String id;
  final String exam;
  final String category;
  final String topic;
  final String text;
  final List<String> choices;
  final int answerIndex;
  final String explanation;

  factory Question.fromFirestore(String id, Map<String, dynamic> data) {
    String requiredString(String key) {
      final value = data[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('questions/$id の $key が不正です');
      }
      return value;
    }

    final rawChoices = data['choices'];
    if (rawChoices is! List || rawChoices.isEmpty) {
      throw FormatException('questions/$id の choices が不正です');
    }
    final choices = rawChoices
        .map((choice) {
          if (choice is! String || choice.trim().isEmpty) {
            throw FormatException('questions/$id の choices に不正な値があります');
          }
          return choice;
        })
        .toList(growable: false);

    final answerIndex = data['answerIndex'];
    if (answerIndex is! int ||
        answerIndex < 0 ||
        answerIndex >= choices.length) {
      throw FormatException('questions/$id の answerIndex が不正です');
    }

    return Question(
      id: id,
      exam: requiredString('exam'),
      category: requiredString('category'),
      topic: requiredString('topic'),
      text: requiredString('question'),
      choices: choices,
      answerIndex: answerIndex,
      explanation: requiredString('explanation'),
    );
  }
}
