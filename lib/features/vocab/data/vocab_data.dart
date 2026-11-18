// 単語帳で使う用語集。
// あとで：チームが作って確認した用語集に置き換える（tool/seed/terms.json はまだ空）。
// 「出てくる問題」は Firestore の問題から探す（providers/related_questions_controller.dart）。

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
