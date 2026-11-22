/// ふりがな付きの文の1単語（tool/questions/add_furigana.py で作る）。
class RubyToken {
  const RubyToken({required this.text, this.parts, this.key});

  /// 文字（例：取り出す）
  final String text;

  /// 漢字の部分ごとの読み（例：[(取, と), (り, null), (出, だ), (す, null)]）。漢字がなければ null。
  final List<(String, String?)>? parts;

  /// タップで意味を出すときの辞書の見出し（例：取り出す）。出さない単語は null。
  final String? key;

  static RubyToken? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final r = raw['r'];
    return RubyToken(
      text: raw['t']?.toString() ?? '',
      parts: r is List
          ? [
              for (final p in r)
                if (p is List && p.isNotEmpty) (p[0].toString(), p.length > 1 ? p[1]?.toString() : null),
            ]
          : null,
      key: raw['k']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        't': text,
        if (parts != null) 'r': [for (final (t, r) in parts!) [t, r]],
        if (key != null) 'k': key,
      };

  static List<RubyToken> listFrom(Object? raw) =>
      raw is List ? raw.map(fromMap).whereType<RubyToken>().toList() : const [];
}

/// 問題文の1かたまり：文章・プログラム・図（画像）。
/// IPA の PDF から作った問題データ（assets/questions/*.json）の "blocks" の1つ。
class QuestionBlock {
  const QuestionBlock({required this.type, this.text = '', this.src, this.ruby = const []});

  /// 'text'（文章） / 'code'（プログラム。字下げをそのまま表示する） / 'image'（図・表）
  final String type;
  final String text;

  /// 画像のファイル名（assets/questions/img/ の中）
  final String? src;

  /// 文章のふりがな（単語ごと）。ない（古いデータ・プログラム・画像）ときは空。
  final List<RubyToken> ruby;

  bool get isImage => type == 'image';
  bool get isCode => type == 'code';

  /// 画像のアセットのパス
  String? get assetPath => src == null ? null : 'assets/questions/img/$src';

  static QuestionBlock? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final type = raw['type']?.toString() ?? 'text';
    return QuestionBlock(
      type: type,
      text: raw['text']?.toString() ?? '',
      src: raw['src']?.toString(),
      ruby: RubyToken.listFrom(raw['ruby']),
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        if (text.isNotEmpty) 'text': text,
        if (src != null) 'src': src,
        if (ruby.isNotEmpty) 'ruby': ruby.map((t) => t.toMap()).toList(),
      };
}

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

  /// 何問目か（IPA の問番号）
  final int? number;

  /// 問題文を、文章・プログラム・図に分けたもの。古いデータでは空。
  final List<QuestionBlock> blocks;

  /// 解答群が表や図のときの画像（assets/questions/img/ の中）。
  /// このときは choices の中身が空で、ア・イ・ウ… のボタンだけを出す。
  final String? choicesImage;

  /// 選択肢のふりがな（choices と同じ順）。ないときは空。
  final List<List<RubyToken>> choicesRuby;

  String? get choicesImagePath => choicesImage == null ? null : 'assets/questions/img/$choicesImage';

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
    this.number,
    this.blocks = const [],
    this.choicesImage,
    this.choicesRuby = const [],
  })  : question = question ?? questionText ?? '',
        choices = choices ?? options ?? const [],
        answerIndex = answerIndex ?? correctIndex ?? 0,
        explanation = explanation ?? '';

  static String? _asNullableString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static String _asString(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    List<String> parsedChoices = [];
    final rawChoices = map['choices'] ?? map['options'];
    if (rawChoices is List) {
      parsedChoices = rawChoices.map((e) => e.toString()).toList();
    } else if (rawChoices is String) {
      parsedChoices = rawChoices.split('|||');
    }

    final rawQuestion = map['question'] ??
        map['questionText'] ??
        map['question_text'] ??
        map['text'];
    final qText = _asString(rawQuestion, fallback: '');

    final rawSubject = map['subject'] ?? map['topic'];
    final subject = _asString(rawSubject, fallback: '科目A');

    final rawTopic = map['topic'] ?? map['subject'];
    final topic = _asString(rawTopic, fallback: '');

    final int ansIndex = answerIndexFromMap(map);

    final rawBlocks = map['blocks'];
    final blocks = rawBlocks is List
        ? rawBlocks.map(QuestionBlock.fromMap).whereType<QuestionBlock>().toList()
        : const <QuestionBlock>[];

    return Question(
      id: map['id'],
      year: _asNullableInt(map['year']),
      exam: _asNullableString(map['exam']),
      subject: subject,
      category: _asString(map['category'], fallback: ''),
      topic: topic,
      question: qText,
      choices: parsedChoices,
      answerIndex: ansIndex,
      explanation: _asString(map['explanation'], fallback: ''),
      source: _asNullableString(map['source']),
      number: _asNullableInt(map['number']),
      blocks: blocks,
      choicesImage: _asNullableString(map['choicesImage']),
      choicesRuby: map['choicesRuby'] is List
          ? [for (final c in map['choicesRuby'] as List) RubyToken.listFrom(c)]
          : const [],
    );
  }

  /// 正解の番号（0 = ア）。
  /// 過去問データ（assets/questions/20xx_kamoku_a.json）は正解を "answer": "エ" のように
  /// 記号で持っているので、番号に直す。番号がなくて記号も読めないときだけ 0。
  static int answerIndexFromMap(Map<String, dynamic> map) {
    final index =
        map['answerIndex'] ?? map['correct_index'] ?? map['correctIndex'];
    if (index is int) return index;
    if (index is num) return index.toInt();
    if (index is String) {
      final parsed = int.tryParse(index.trim());
      if (parsed != null) return parsed;
    }

    final answer = map['answer'];
    if (answer is int) return answer;
    if (answer is num) return answer.toInt();
    if (answer is String) {
      const symbols = ['ア', 'イ', 'ウ', 'エ', 'オ', 'カ', 'キ', 'ク'];
      final i = symbols.indexOf(answer.trim());
      if (i >= 0) return i;
    }
    return 0;
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
      if (number != null) 'number': number,
      if (blocks.isNotEmpty) 'blocks': blocks.map((b) => b.toMap()).toList(),
      if (choicesImage != null) 'choicesImage': choicesImage,
      if (choicesRuby.isNotEmpty) 'choicesRuby': [for (final c in choicesRuby) c.map((t) => t.toMap()).toList()],
    };
  }
}