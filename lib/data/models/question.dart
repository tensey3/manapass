class Question {
  final Object? id;
  final int? year;
  final String? exam;
  final String subject;
  final String category;
  final String topic;

  final String question;
  final List<String> choices;
  final int answerIndex;

  final String explanation;
  final String? source;

  // --- 互換性のための Getter ---
  String get questionText => question;
  List<String> get options => choices;
  int get correctIndex => answerIndex;

  // どちらのパラメータ名（新旧）で渡されても両方受け取れるコンストラクタ
  Question({
    this.id,
    this.year,
    this.exam,
    this.subject = '科目A',
    this.category = '',
    this.topic = '',
    String? question,
    String? questionText,
    List<String>? choices,
    List<String>? options,
    int? answerIndex,
    int? correctIndex,
    String? explanation,
    this.source,
  })  : question = question ?? questionText ?? '',
        choices = choices ?? options ?? const [],
        answerIndex = answerIndex ?? correctIndex ?? 0,
        explanation = explanation ?? '';

  factory Question.fromMap(Map<String, dynamic> map) {
    List<String> parsedChoices = [];
    final rawChoices = map['choices'] ?? map['options'];
    if (rawChoices is List) {
      parsedChoices = rawChoices.map((e) => e.toString()).toList();
    } else if (rawChoices is String) {
      parsedChoices = rawChoices.split('|||');
    }

    String qText = map['question'] ??
        map['questionText'] ??
        map['question_text'] ??
        map['text'] ??
        '';

    int ansIndex = map['answerIndex'] ?? map['correct_index'] ?? 0;

    return Question(
      id: map['id'],
      year: map['year'] as int?,
      exam: map['exam'] as String?,
      subject: map['subject'] ?? map['topic'] ?? '科目A',
      category: map['category'] ?? '',
      topic: map['topic'] ?? map['subject'] ?? '',
      question: qText,
      choices: parsedChoices,
      answerIndex: ansIndex,
      explanation: map['explanation'] ?? '',
      source: map['source'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'exam': exam,
      'subject': subject,
      'category': category,
      'topic': topic,
      'question': question,
      'choices': choices,
      'answerIndex': answerIndex,
      'explanation': explanation,
      'source': source,
    };
  }
}