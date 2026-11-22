"""問題データにふりがなと「タップで意味」を付ける。

使い方（extract_new.py で問題を作ったあとに実行する）:
    python tool/questions/add_furigana.py <JMdict_e.gz のパス>

必要なもの（無料）:
    pip install fugashi unidic-lite        … 日本語を単語に分けて読みを出す
    JMdict_e.gz                            … 和英辞書（EDRDG, CC BY-SA 4.0）
        http://ftp.edrdg.org/pub/Nihongo/JMdict_e.gz

やること:
    assets/questions/*.json
        文章ブロックに "ruby"、文の選択肢に "choicesRuby" を足す。
        ruby は単語の並び: {"t": 文字, "r": [[漢字, よみ], [かな, null], ...], "k": 辞書の見出し}
        （r は漢字があるときだけ。k はタップで意味が出る単語だけ）
    assets/dict/words.json
        問題に出てくる単語だけの辞書 {見出し: {"reading": よみ, "meaning": 英語の意味}}。
        アプリの用語集（lib/features/vocab/data/vocab_data.dart）にある言葉は入れない（用語集の意味を使う）。
"""

import gzip
import json
import os
import re
import sys
import xml.etree.ElementTree as ET

import fugashi

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
QDIR = os.path.join(ROOT, 'assets', 'questions')
DICT_OUT = os.path.join(ROOT, 'assets', 'dict', 'words.json')
GLOSSARY_DART = os.path.join(ROOT, 'lib', 'features', 'vocab', 'data', 'vocab_data.dart')

KANJI = re.compile(r'[㐀-鿿々]')  # 漢字と「々」
# タップで意味を出す品詞
CONTENT_POS = {'名詞', '動詞', '形容詞', '形状詞', '副詞'}
# よく出るけど意味を出してもしかたない言葉
STOP = set('する ある いる なる できる れる られる せる させる こと もの ため よう とき ところ これ それ あれ どれ この その どの ここ そこ 何 次 方 等 際 中 上 下 後 前 用 的 化 性 者 時 場合 おく よる'.split())
# 単語どうしをつなげて辞書を引くときの品詞（例：浮動 + 小数 + 点 → 浮動小数点）
JOIN_POS = {'名詞', '接尾辞', '接頭辞'}
# 読みまちがいを直す（前の文字・次の文字を見て決める）: (この文字, 前の単語の条件, 次の単語の条件, 正しい読み)
FIX_READING = [
    ('日', lambda prev, nxt: prev[-1:].isdigit(), 'にち'),   # 1日 → いちにち
    ('分', lambda prev, nxt: nxt.startswith('探索'), 'ぶん'),  # 2分探索 → にぶんたんさく
    ('木', lambda prev, nxt: prev.endswith('探索'), 'ぎ'),     # 探索木 → たんさくぎ
]
MAX_MEANING = 70  # 意味が長すぎるときは、よく使う意味だけにする


def hira(s):
    """カタカナをひらがなにする（ー などはそのまま）。"""
    return ''.join(chr(ord(c) - 0x60) if 'ァ' <= c <= 'ヶ' else c for c in s)


def split_okurigana(surface, reading):
    """「取り出す / とりだす」→ [["取","と"],["り",None],["出","だ"],["す",None]]。
    漢字の部分にだけ読みを付ける。うまく合わないときは全体に読みを付ける。"""
    parts = re.findall(r'[㐀-鿿々]+|[^㐀-鿿々]+', surface)
    pattern = ''.join('(.+?)' if KANJI.match(p) else '(' + re.escape(hira(p)) + ')' for p in parts)
    m = re.fullmatch(pattern, reading)
    if not m:
        return [[surface, reading]]
    return [[p, g if KANJI.match(p) else None] for p, g in zip(parts, m.groups())]


def load_glossary():
    """アプリの用語集の言葉（見出しと読み）。"""
    src = open(GLOSSARY_DART, encoding='utf-8').read()
    out = {}
    for m in re.finditer(r"Word\(text: '([^']+)'(?:, reading: '([^']+)')?", src):
        out[m.group(1)] = m.group(2)
    return out


def load_jmdict(path):
    """JMdict を {書き方: (よみ, 意味)} にする。最初に出てきた見出しを使う。"""
    entries = {}
    with gzip.open(path, 'rb') as f:
        for _, el in ET.iterparse(f, events=('end',)):
            if el.tag != 'entry':
                continue
            kebs = [k.text for k in el.findall('k_ele/keb')]
            rebs = [r.text for r in el.findall('r_ele/reb')]
            meaning = ''
            for s in el.findall('sense')[:3]:
                gl = ', '.join(g.text for g in s.findall('gloss')[:3] if g.text)
                if not gl:
                    continue
                if meaning and len(meaning) + len(gl) > MAX_MEANING:
                    break
                meaning = gl if not meaning else meaning + '; ' + gl
            if meaning and rebs:
                value = (hira(rebs[0]), meaning)
                for form in kebs + rebs:
                    entries.setdefault(form, value)
            el.clear()
    return entries


class Annotator:
    def __init__(self, glossary, jmdict):
        self.tagger = fugashi.Tagger()
        self.glossary = glossary
        self.jmdict = jmdict
        self.used = {}  # 使った辞書の見出し → (よみ, 意味)
        # 用語集は長い言葉から先に探す
        self.terms = sorted(glossary, key=len, reverse=True)

    def tokens(self, text):
        out = []
        pos = 0
        for w in self.tagger(text):
            s = w.surface
            start = text.find(s, pos)
            if start < 0:
                continue
            if start > pos:  # 空白など
                out.append({'t': text[pos:start]})
            f = w.feature
            kana = getattr(f, 'kana', None) or ''
            base = getattr(f, 'orthBase', None) or s
            pos1 = getattr(f, 'pos1', '')
            tok = {'t': s, '_base': base, '_pos': pos1}
            if KANJI.search(s) and kana and kana != '*':
                tok['r'] = split_okurigana(s, hira(kana))
            out.append(tok)
            pos = start + len(s)
        if pos < len(text):
            out.append({'t': text[pos:]})
        return out

    def merge_glossary(self, toks):
        """用語集の言葉（例：排他制御）は、分かれた単語を1つにまとめる。"""
        out = []
        i = 0
        while i < len(toks):
            done = False
            for term in self.terms:
                acc = ''
                j = i
                while j < len(toks) and len(acc) < len(term):
                    acc += toks[j]['t']
                    j += 1
                if acc == term and j - i >= 1:
                    reading = self.glossary[term]
                    r = None
                    if KANJI.search(term):
                        if reading:
                            r = split_okurigana(term, reading)
                        else:
                            r = [p for t in toks[i:j] for p in (t.get('r') or [[t['t'], None]])]
                    tok = {'t': term, 'k': term}
                    if r:
                        tok['r'] = r
                    out.append(tok)
                    i = j
                    done = True
                    break
            if not done:
                out.append(toks[i])
                i += 1
        return out

    def link(self, tok):
        """タップで意味を出せる単語なら、辞書の見出しを付ける。"""
        if 'k' in tok or '_base' not in tok:
            return
        base = tok['_base']
        if tok['_pos'] not in CONTENT_POS or base in STOP or tok['t'] in STOP:
            return
        if len(base) == 1 and not KANJI.search(base):
            return
        if base in self.glossary:
            tok['k'] = base
            return
        for form in (base, tok['t']):
            if form in self.jmdict:
                tok['k'] = form
                self.used[form] = self.jmdict[form]
                return

    def fix_readings(self, toks):
        for i, t in enumerate(toks):
            prev = toks[i - 1]['t'] if i else ''
            nxt = toks[i + 1]['t'] if i + 1 < len(toks) else ''
            for ch, cond, reading in FIX_READING:
                if t['t'] == ch and cond(prev, nxt):
                    t['r'] = [[ch, reading]]
        return toks

    def join_compounds(self, toks):
        """続いている名詞をつなげた言葉が辞書にあれば、1つの単語にする（長いものから）。"""
        out = []
        i = 0
        while i < len(toks):
            merged = False
            for n in range(5, 1, -1):
                part = toks[i:i + n]
                if len(part) < n or any(t.get('_pos') not in JOIN_POS or 'k' in t for t in part):
                    continue
                word = ''.join(t['t'] for t in part)
                if word in self.jmdict or word in self.glossary:
                    r = [p for t in part for p in (t.get('r') or [[t['t'], None]])]
                    tok = {'t': word, '_base': word, '_pos': '名詞'}
                    if any(rr for _, rr in r):
                        tok['r'] = r
                    out.append(tok)
                    i += n
                    merged = True
                    break
            if not merged:
                out.append(toks[i])
                i += 1
        return out

    def annotate(self, text):
        toks = self.join_compounds(self.merge_glossary(self.fix_readings(self.tokens(text))))
        for t in toks:
            self.link(t)
        # 読みも見出しもない文字はまとめて小さくする
        out = []
        for t in toks:
            t = {k: v for k, v in t.items() if not k.startswith('_')}
            if len(t) == 1 and out and len(out[-1]) == 1:
                out[-1]['t'] += t['t']
            else:
                out.append(t)
        assert ''.join(t['t'] for t in out) == text, text[:40]
        return out


def main(jmdict_path):
    glossary = load_glossary()
    print('用語集', len(glossary), '語')
    jmdict = load_jmdict(jmdict_path)
    print('JMdict', len(jmdict), '見出し')
    ann = Annotator(glossary, jmdict)
    index = json.load(open(os.path.join(QDIR, 'index.json'), encoding='utf-8'))
    linked = 0
    for exam in index['exams']:
        path = os.path.join(QDIR, exam['file'])
        qs = json.load(open(path, encoding='utf-8'))
        for q in qs:
            for b in q['blocks']:
                if b['type'] == 'text':
                    b['ruby'] = ann.annotate(b['text'])
                    linked += sum(1 for t in b['ruby'] if 'k' in t)
            if not q.get('choicesImage'):
                q['choicesRuby'] = [ann.annotate(c) for c in q['choices']]
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(qs, f, ensure_ascii=False, indent=1)
    words = {k: {'reading': r if KANJI.search(k) else None, 'meaning': m}
             for k, (r, m) in sorted(ann.used.items()) if k not in glossary}
    os.makedirs(os.path.dirname(DICT_OUT), exist_ok=True)
    with open(DICT_OUT, 'w', encoding='utf-8') as f:
        json.dump(words, f, ensure_ascii=False, separators=(',', ':'))
    print('タップできる単語（のべ）', linked, '/ 辞書', len(words), '語')


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    main(sys.argv[1])
