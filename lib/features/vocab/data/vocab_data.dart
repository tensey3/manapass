// 単語帳で使う見本のデータ。
// あとで：用語集はチームが作って確認したものに、問題はIPAの過去問題に置き換える。
// 下の問題は見本として自分たちで書いたもので、IPAの過去問題ではない。

/// 英語の意味をどこから持ってきたか（どのくらい信用できるか）。
enum WordLabel {
  checked, // チームが確認した用語集
  general, // 一般の辞書：ITの意味と合わないことがある
  auto, // 自動翻訳：まちがっている可能性がある
}

/// 用語集の1語。
class Word {
  const Word({required this.text, this.reading, required this.meaning, this.label = WordLabel.checked});

  final String text; // 問題に書かれているとおり（例：排他制御）
  final String? reading; // ひらがな。カタカナの言葉は null
  final String meaning; // 英語の意味
  final WordLabel label;
}

const _words = [
  Word(text: 'データベース', meaning: 'database'),
  Word(text: 'トランザクション', meaning: 'transaction (a group of operations processed as one unit)'),
  Word(text: '処理', reading: 'しょり', meaning: 'processing'),
  Word(text: '排他制御', reading: 'はいたせいぎょ', meaning: 'exclusive control; locking (stops two users updating the same data at once)'),
  Word(text: '適切', reading: 'てきせつ', meaning: 'appropriate; suitable', label: WordLabel.general),
  Word(text: '同時', reading: 'どうじ', meaning: 'at the same time; simultaneous', label: WordLabel.general),
  Word(text: '更新', reading: 'こうしん', meaning: 'update'),
  Word(text: '整合性', reading: 'せいごうせい', meaning: 'consistency; integrity (data has no contradictions)'),
  Word(text: '障害', reading: 'しょうがい', meaning: 'failure; fault'),
  Word(text: '障害発生前', reading: 'しょうがいはっせいまえ', meaning: 'before the failure occurred', label: WordLabel.auto),
  Word(text: '権限', reading: 'けんげん', meaning: 'permission; access right'),
  Word(text: '索引', reading: 'さくいん', meaning: 'index (makes searching faster)'),
  Word(text: 'ネットワーク', meaning: 'network'),
  Word(text: 'IPアドレス', meaning: 'IP address'),
  Word(text: 'ホスト', meaning: 'host (a computer connected to a network)'),
  Word(text: '割り当て', reading: 'わりあて', meaning: 'assignment; allocation'),
  Word(text: 'ネットワークアドレス', meaning: 'network address (all host bits are 0)'),
  Word(text: 'ブロードキャストアドレス', meaning: 'broadcast address (all host bits are 1)'),
  Word(text: '公開鍵暗号方式', reading: 'こうかいかぎあんごうほうしき', meaning: 'public-key cryptography'),
  Word(text: '暗号化', reading: 'あんごうか', meaning: 'encryption'),
  Word(text: '復号', reading: 'ふくごう', meaning: 'decryption'),
  Word(text: '公開鍵', reading: 'こうかいかぎ', meaning: 'public key'),
  Word(text: '秘密鍵', reading: 'ひみつかぎ', meaning: 'private key'),
  Word(text: '10進数', reading: 'じっしんすう', meaning: 'decimal number (base 10)'),
  Word(text: '2進数', reading: 'にしんすう', meaning: 'binary number (base 2)'),
  Word(text: '16進数', reading: 'じゅうろくしんすう', meaning: 'hexadecimal number (base 16)'),
  Word(text: 'スタック', meaning: 'stack (the last item added is the first taken out)'),
  Word(text: '格納', reading: 'かくのう', meaning: 'storing (data); storage'),
  Word(text: 'LIFO', meaning: 'LIFO: last in, first out'),
  Word(text: 'データ構造', reading: 'データこうぞう', meaning: 'data structure'),
  Word(text: 'フィッシング', meaning: 'phishing (stealing passwords with fake emails or websites)'),
  Word(text: 'DoS攻撃', reading: 'ドスこうげき', meaning: 'DoS attack (overloads a service so it stops working)'),
  Word(text: 'SQLインジェクション', meaning: 'SQL injection (running unauthorized SQL on a database)'),
  Word(text: 'ブルートフォース攻撃', reading: 'ブルートフォースこうげき', meaning: 'brute-force attack (trying every possible password)'),
  Word(text: '関係データベース', reading: 'かんけいデータベース', meaning: 'relational database'),
  Word(text: '一意', reading: 'いちい', meaning: 'unique (exactly one)'),
  Word(text: '識別', reading: 'しきべつ', meaning: 'identification; telling apart', label: WordLabel.general),
  Word(text: '主キー', reading: 'しゅキー', meaning: 'primary key'),
  Word(text: '外部キー', reading: 'がいぶキー', meaning: 'foreign key'),
  Word(text: 'ビュー', meaning: 'view (a virtual table made from other tables)'),
  Word(text: '閲覧', reading: 'えつらん', meaning: 'browsing; viewing', label: WordLabel.general),
  Word(text: 'プロトコル', meaning: 'protocol (rules for communication)'),
  Word(text: 'HTTP', meaning: 'HTTP: protocol for web pages'),
  Word(text: 'SMTP', meaning: 'SMTP: protocol for sending email'),
  Word(text: 'FTP', meaning: 'FTP: protocol for transferring files'),
  Word(text: 'DNS', meaning: 'DNS: turns domain names into IP addresses'),
  Word(text: '階層的', reading: 'かいそうてき', meaning: 'hierarchical; in levels'),
  Word(text: '分解', reading: 'ぶんかい', meaning: 'breaking down; decomposition', label: WordLabel.general),
  Word(text: 'WBS', meaning: 'WBS: work breakdown structure'),
  Word(text: 'ガントチャート', meaning: 'Gantt chart (bars showing the schedule of tasks)'),
  Word(text: 'アローダイアグラム', meaning: 'arrow diagram (shows the order of tasks)'),
  Word(text: 'マイルストーン', meaning: 'milestone (an important point in a project)'),
  Word(text: 'OSI基本参照モデル', reading: 'OSIきほんさんしょうモデル', meaning: 'OSI reference model (7 layers of network communication)'),
];

/// 書かれた言葉で引ける用語集（例：glossary['排他制御']）。
final glossary = {for (final w in _words) w.text: w};

/// アプリを初めて開いたときに単語帳に入っている単語。
const initialSavedWords = ['トランザクション', '排他制御', '整合性', '暗号化', '公開鍵', 'スタック', '索引', '権限'];

/// 「出てくる問題」に表示する見本の問題（問題文と選択肢）。
/// 書き方：[排他制御|はいたせいぎょ] = 読みつきの言葉、[トランザクション] = 読みなしの言葉。
class SampleQuestion {
  const SampleQuestion({required this.number, required this.topic, required this.body, required this.choices});

  final int number;
  final String topic;
  final String body;
  final List<String> choices;

  /// 画面に出す出典（例：サンプル問題・問3）。
  String get source => 'サンプル問題・問$number';

  /// かっこと読みを取った問題文。
  String get plainBody => body.replaceAllMapped(_bracket, (m) => m[1]!);

  /// この問題に [word] が出てくるか。
  bool contains(String word) =>
      [body, ...choices].any((t) => t.contains('[$word|') || t.contains('[$word]'));
}

final _bracket = RegExp(r'\[([^\]|]+)(?:\|([^\]]+))?\]');

/// [word] が出てくる見本の問題。
List<SampleQuestion> questionsWith(String word) => sampleQuestions.where((q) => q.contains(word)).toList();

const sampleQuestions = [
  SampleQuestion(
    number: 1,
    topic: 'データベース',
    body: '[データベース]の[トランザクション][処理|しょり]において、[排他制御|はいたせいぎょ]を[行|おこな]う'
        '[目的|もくてき]として、[最|もっと]も[適切|てきせつ]なものはどれか。',
    choices: [
      '[複数|ふくすう]の[トランザクション]が[同|おな]じデータを[同時|どうじ]に[更新|こうしん]して、'
          'データの[整合性|せいごうせい]が[失|うしな]われることを[防|ふせ]ぐ。',
      '[障害|しょうがい]が[発生|はっせい]したときに、[データベース]を[障害発生前|しょうがいはっせいまえ]の'
          '[状態|じょうたい]に[戻|もど]す。',
      '[データベース]へのアクセス[権限|けんげん]を[利用者|りようしゃ]ごとに[設定|せってい]する。',
      '[検索|けんさく][処理|しょり]を[高速|こうそく]にするために、[索引|さくいん]を[作成|さくせい]する。',
    ],
  ),
  SampleQuestion(
    number: 2,
    topic: 'ネットワーク',
    body: '[IPアドレス] 192.168.1.0/24 の[ネットワーク]で、[ホスト]に[割り当て|わりあて]ることが'
        'できる[IPアドレス]の[最大数|さいだいすう]はどれか。',
    choices: ['24', '254', '255', '256'],
  ),
  SampleQuestion(
    number: 3,
    topic: 'セキュリティ',
    body: '[公開鍵暗号方式|こうかいかぎあんごうほうしき]でデータを[暗号化|あんごうか]し、[特定|とくてい]の'
        '[相手|あいて]だけが[復号|ふくごう]できるようにしたい。[暗号化|あんごうか]に[使|つか]う[鍵|かぎ]として、'
        '[適切|てきせつ]なものはどれか。',
    choices: [
      '[自分|じぶん]の[秘密鍵|ひみつかぎ]',
      '[自分|じぶん]の[公開鍵|こうかいかぎ]',
      '[相手|あいて]の[秘密鍵|ひみつかぎ]',
      '[相手|あいて]の[公開鍵|こうかいかぎ]',
    ],
  ),
  SampleQuestion(
    number: 4,
    topic: '基礎理論',
    body: '[10進数|じっしんすう]の 13 を[2進数|にしんすう]で[表|あらわ]したものはどれか。',
    choices: ['1011', '1101', '1110', '1001'],
  ),
  SampleQuestion(
    number: 5,
    topic: 'アルゴリズム',
    body: '[スタック]に 1、2、3 の[順|じゅん]にデータを[格納|かくのう]した[後|あと]、データを 2 [回|かい]'
        '[取|と]り[出|だ]した。2 [回目|かいめ]に[取|と]り[出|だ]されるデータはどれか。',
    choices: ['1', '2', '3', '[取|と]り[出|だ]せない'],
  ),
  SampleQuestion(
    number: 6,
    topic: 'セキュリティ',
    body: '[送信者|そうしんしゃ]を[偽|いつわ]った[電子|でんし]メールで[受信者|じゅしんしゃ]を[偽|にせ]の'
        'Webサイトに[誘導|ゆうどう]し、IDやパスワードなどを[盗|ぬす]み[取|と]る[攻撃|こうげき]はどれか。',
    choices: [
      '[フィッシング]',
      '[DoS攻撃|ドスこうげき]',
      '[SQLインジェクション]',
      '[ブルートフォース攻撃|ブルートフォースこうげき]',
    ],
  ),
  SampleQuestion(
    number: 7,
    topic: 'データベース',
    body: '[関係データベース|かんけいデータベース]の[表|ひょう]で、[各行|かくぎょう]を[一意|いちい]に'
        '[識別|しきべつ]するために[使|つか]う[列|れつ]（または[列|れつ]の[組|く]み[合|あ]わせ）はどれか。',
    choices: ['[外部キー|がいぶキー]', '[主キー|しゅキー]', '[索引|さくいん]', '[ビュー]'],
  ),
  SampleQuestion(
    number: 8,
    topic: 'ネットワーク',
    body: 'Webページを[閲覧|えつらん]するときに、WebブラウザとWebサーバの[間|あいだ]で[使|つか]われる'
        '[プロトコル]はどれか。',
    choices: ['[HTTP]', '[SMTP]', '[FTP]', '[DNS]'],
  ),
  SampleQuestion(
    number: 9,
    topic: 'マネジメント',
    body: 'プロジェクトの[作業|さぎょう]を[階層的|かいそうてき]に[分解|ぶんかい]し、[管理|かんり]しやすい'
        '[単位|たんい]にまとめたものはどれか。',
    choices: ['[WBS]', '[ガントチャート]', '[アローダイアグラム]', '[マイルストーン]'],
  ),
  SampleQuestion(
    number: 10,
    topic: '基礎理論',
    body: '[16進数|じゅうろくしんすう]の 1F を[10進数|じっしんすう]で[表|あらわ]したものはどれか。',
    choices: ['15', '25', '31', '32'],
  ),
];
