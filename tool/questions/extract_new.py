"""IPA の新形式 PDF（2023年度〜の公開問題・2022年のサンプル問題）から問題データを作る。

使い方:
    python tool/questions/extract_new.py <PDFフォルダ> <出力フォルダ>

PDF フォルダには IPA の PDF を元のファイル名のまま置く
（例: 2025r07_fe_kamoku_a_qs.pdf と 2025r07_fe_kamoku_a_ans.pdf）。
出力:
    <出力フォルダ>/<試験ID>.json      … 1回分の問題（例: 2025r07_a.json）
    <出力フォルダ>/img/<問題ID>_*.png … 図・表・解答群の画像

正解は IPA の解答例 PDF から読むので、手で入れる必要はない。
"""

import json
import os
import re
import sys
import unicodedata

import pymupdf

LABELS = 'アイウエオカキクケコサシスセソ'
ZOOM_DPI = 200

# (PDFの名前の頭, 試験ID, 年, 科目, 出典の書き方)
EXAMS = [
    ('2023r05_fe_kamoku_a', '2023r05_a', 2023, 'A', '令和5年度 基本情報技術者試験 公開問題 科目A'),
    ('2023r05_fe_kamoku_b', '2023r05_b', 2023, 'B', '令和5年度 基本情報技術者試験 公開問題 科目B'),
    ('2024r06_fe_kamoku_a', '2024r06_a', 2024, 'A', '令和6年度 基本情報技術者試験 公開問題 科目A'),
    ('2024r06_fe_kamoku_b', '2024r06_b', 2024, 'B', '令和6年度 基本情報技術者試験 公開問題 科目B'),
    ('2025r07_fe_kamoku_a', '2025r07_a', 2025, 'A', '令和7年度 基本情報技術者試験 公開問題 科目A'),
    ('2025r07_fe_kamoku_b', '2025r07_b', 2025, 'B', '令和7年度 基本情報技術者試験 公開問題 科目B'),
    ('2026r08_fe_kamoku_a', '2026r08_a', 2026, 'A', '令和8年度 基本情報技術者試験 公開問題 科目A'),
    ('2026r08_fe_kamoku_b', '2026r08_b', 2026, 'B', '令和8年度 基本情報技術者試験 公開問題 科目B'),
    ('fe_kamoku_a_set_sample', '2022sample_a', 2022, 'A', '基本情報技術者試験 サンプル問題 科目A'),
    ('fe_kamoku_b_set_sample', '2022sample_b', 2022, 'B', '基本情報技術者試験 サンプル問題 科目B'),
]


def nfkc(s):
    return unicodedata.normalize('NFKC', s)


def read_answers(path):
    text = nfkc(''.join(p.get_text() for p in pymupdf.open(path)))
    return {int(n): k for n, k in re.findall(r'問\s*(\d+)\s*([' + LABELS + '])', text)}


class Item:
    """1行の中の、ひとかたまりの文字（PyMuPDF の line）。"""

    def __init__(self, page, bbox, text):
        self.page = page
        self.x0, self.y0, self.x1, self.y1 = bbox
        self.text = text

    @property
    def cx(self):
        return (self.x0 + self.x1) / 2

    @property
    def cy(self):
        return (self.y0 + self.y1) / 2


def page_items(page):
    items = []
    h = page.rect.height
    for b in page.get_text('dict')['blocks']:
        if b['type'] != 0:
            continue
        for line in b['lines']:
            text = ''.join(s['text'] for s in line['spans'])
            if not text.strip():
                continue
            it = Item(page.number, line['bbox'], text.rstrip())
            if re.sub(r'\s', '', nfkc(text)) in ('〔メモ用紙〕', '[メモ用紙]'):
                continue
            # 最後のページの商標・著作権の注意書き
            if '登録商標' in text or 'TM 及び' in text or '©' in text:
                continue
            # ヘッダー・ページ番号（－ 3 －）は捨てる
            if it.y1 < 50 or it.y0 > h - 60:
                continue
            items.append(it)
    return items


def is_question_start(it):
    return it.x0 < 64 and re.match(r'^問\s*\d+', nfkc(it.text)) is not None


def question_number(it):
    return int(re.match(r'^問\s*(\d+)', nfkc(it.text)).group(1))


def cluster_rects(rects, gap=6):
    """近くにある図形をまとめて、図・表ごとの範囲にする。"""
    boxes = [pymupdf.Rect(r) for r in rects]
    merged = True
    while merged:
        merged = False
        out = []
        for r in boxes:
            for k, o in enumerate(out):
                if (r + (-gap, -gap, gap, gap)).intersects(o):
                    out[k] = pymupdf.Rect(o) | r
                    merged = True
                    break
            else:
                out.append(pymupdf.Rect(r))
        boxes = out
    return boxes


class Question:
    def __init__(self, number):
        self.number = number
        self.parts = []  # [(page, y_from, y_to)]
        self.items = []


def split_questions(doc):
    questions = []
    cur = None
    for page in doc:
        items = sorted(page_items(page), key=lambda i: (round(i.y0), i.x0))
        starts = [i for i in items if is_question_start(i)]
        if cur is None and not starts:
            continue  # 表紙・擬似言語の説明ページ
        y = 50
        for s in starts:
            if cur is not None:
                cur.parts.append((page.number, y, s.y0 - 2))
            cur = Question(question_number(s))
            questions.append(cur)
            y = s.y0 - 2
        if cur is not None:
            cur.parts.append((page.number, y, page.rect.height - 60))
    for q in questions:
        for pno, y0, y1 in q.parts:
            q.items += [i for i in page_items(doc[pno]) if y0 <= i.cy <= y1]
    return questions


def find_blank_boxes(page, items, y0, y1):
    """プログラムや文中の空欄（a, b … の入った小さな四角）を見つける。"""
    blanks, others = [], []
    for d in page.get_drawings():
        r = d['rect']
        # 線のない白い四角は見えない（IPA が PDF を直した跡）ので無視する
        fill = d.get('fill')
        if d.get('color') is None and (fill is None or min(fill) > 0.95):
            continue
        if not (y0 <= (r.y0 + r.y1) / 2 <= y1):
            continue
        inside = [i for i in items if r.contains(pymupdf.Point(i.cx, i.cy))]
        label = nfkc(inside[0].text.strip()) if len(inside) == 1 else ''
        if 14 <= r.width <= 90 and 8 <= r.height <= 22 and re.fullmatch(r'[a-z]', label):
            blanks.append((r, inside[0]))
        elif 14 <= r.width <= 120 and 8 <= r.height <= 22 and not inside:
            blanks.append((r, None))
        elif r.width > 2 or r.height > 2:
            others.append(r)
    return blanks, others


def rows_of(items):
    """同じ高さの文字を1行にまとめる（左から右へ）。"""
    rows = []
    for it in sorted(items, key=lambda i: (i.page, i.y0, i.x0)):
        if rows and rows[-1][0].page == it.page and abs(rows[-1][0].y0 - it.y0) <= 3:
            rows[-1].append(it)
        else:
            rows.append([it])
    return [sorted(r, key=lambda i: i.x0) for r in rows]


def row_text(row):
    out = ''
    for i, it in enumerate(row):
        t = it.text
        if i and it.x0 - row[i - 1].x1 > 6 and not out.endswith(' ') and not t.startswith(' '):
            out += ' '
        out += t
    return out


def label_of(it):
    m = re.match(r'^([' + LABELS + r'])(?:[ 　]+(.*))?$', it.text.strip())
    if not m:
        return None
    return m.group(1), (m.group(2) or '').strip()


def save_clip(doc, pno, rect, path):
    pix = doc[pno].get_pixmap(clip=rect, dpi=ZOOM_DPI)
    pix.save(path)


def stitch(paths, out):
    """2ページにまたがった解答群の画像を縦につなげる。"""
    from PIL import Image
    imgs = [Image.open(p) for p in paths]
    w = max(i.width for i in imgs)
    canvas = Image.new('RGB', (w, sum(i.height for i in imgs)), 'white')
    y = 0
    for i in imgs:
        canvas.paste(i, (0, y))
        y += i.height
    canvas.save(out)
    for i, p in zip(imgs, paths):
        i.close()
        os.remove(p)


def build(doc, q, exam_id, img_dir, answer):
    qid = f'{exam_id}_{q.number:02d}'
    # 1) ページごとに空欄と図を見つける
    figures = []  # (page, rect)
    blank_items = {}
    for pno, y0, y1 in q.parts:
        page = doc[pno]
        items = [i for i in q.items if i.page == pno]
        blanks, others = find_blank_boxes(page, items, y0, y1)
        for r, it in blanks:
            if it is None:
                it = Item(pno, (r.x0, r.y0, r.x1, r.y1), '［　］')
                q.items.append(it)
                blank_items[id(it)] = '　'
            else:
                blank_items[id(it)] = nfkc(it.text.strip())
        # 図は横いっぱいのかたまりなので、上下が重なる・近いものは1つの図にまとめる
        # （表の罫線は1本ずつだと細い線なので、まとめてから小さすぎるものを捨てる）
        boxes = sorted(cluster_rects(others, gap=10), key=lambda r: r.y0)
        merged = []
        for r in boxes:
            if merged and r.y0 <= merged[-1].y1 + 30:
                merged[-1] |= r
            else:
                merged.append(pymupdf.Rect(r))
        figures += [(pno, r) for r in merged if r.width >= 12 and r.height >= 8]
    # 図の中の文字は図の一部（画像）として扱う
    def in_figure(it):
        for pno, r in figures:
            if pno == it.page and (r + (-16, -3, 16, 3)).contains(pymupdf.Point(it.cx, it.cy)):
                return (pno, r)
        return None

    for it in q.items:
        if id(it) in blank_items:
            it.text = f'［{blank_items[id(it)]}］'
    # 図の範囲に、図の中の文字も入るように広げる
    grown = []
    for pno, r in figures:
        rr = pymupdf.Rect(r)
        for it in q.items:
            if it.page == pno and (r + (-16, -3, 16, 3)).contains(pymupdf.Point(it.cx, it.cy)):
                rr |= pymupdf.Rect(it.x0, it.y0, it.x1, it.y1)
        grown.append((pno, rr))
    figures = grown

    text_items = [i for i in q.items if not in_figure(i)]
    rows = rows_of(text_items)
    # 最初の行の「問１」を取る
    first = rows[0][0]
    first.text = re.sub(r'^問\s*[0-9０-９]+\s*', '', first.text)

    # 2) 解答群（ア イ ウ …）の始まりを探す
    choice_start = None
    for idx, row in enumerate(rows):
        lab = label_of(row[0])
        if lab and lab[0] == 'ア':
            choice_start = idx
            break
    # 図の中に解答群がある（表になった解答群など）
    fig_labels = set()
    for pno, r in figures:
        for it in q.items:
            if it.page == pno and (r + (-16, -3, 16, 3)).contains(pymupdf.Point(it.cx, it.cy)):
                lab = label_of(it)
                if lab:
                    fig_labels.add(lab[0])

    # 科目B の解答群は表になっていることが多いので、「解答群」から下をまるごと画像にする
    kaitou = None
    if exam_id.endswith('_b'):
        for k, row in enumerate(rows):
            head = re.sub(r'\s', '', nfkc(row_text(row)))
            if head.endswith('解答群') and len(head) <= 15:
                kaitou = k
                break
        if kaitou is not None:
            choice_start = kaitou
    stem_end = choice_start

    # 3) 問題文のブロック（文章・プログラム・図）を上から順に並べる
    stem_rows = rows if choice_start is None else rows[:stem_end]
    stem_bottom = None if choice_start is None else (rows[stem_end][0].page, rows[stem_end][0].y0)
    blocks = []
    fig_n = 0

    def add_text(t, kind='text'):
        if blocks and blocks[-1]['type'] == kind:
            sep = '\n'
            if kind == 'text' and blocks[-1].get('_wrap'):
                sep = ''
            blocks[-1]['text'] += sep + t
        else:
            blocks.append({'type': kind, 'text': t})

    in_program = False
    events = [(r[0].page, r[0].y0, 'row', r) for r in stem_rows]
    for pno, r in figures:
        if stem_bottom is None or (pno, r.y0) < stem_bottom:
            events.append((pno, r.y0, 'fig', r))
    events.sort(key=lambda e: (e[0], e[1]))
    for pno, y, kind, obj in events:
        if kind == 'fig':
            fig_n += 1
            name = f'{qid}_{fig_n}.png'
            save_clip(doc, pno, obj + (-4, -4, 4, 4), os.path.join(img_dir, name))
            blocks.append({'type': 'image', 'src': name})
            in_program = False
            continue
        row = obj
        t = row_text(row)
        plain = nfkc(t).strip()
        if plain.startswith('〔プログラム') or plain.startswith('[プログラム'):
            in_program = True
            add_text(plain)
            blocks[-1]['_wrap'] = False
            continue
        if plain == '解答群':
            continue
        if in_program and row[0].x0 >= 90:
            add_text(t.rstrip()[ (0 if not t.startswith(' ') else 0):], 'code')
            continue
        in_program = False
        add_text(t.strip())
        blocks[-1]['_wrap'] = row[-1].x1 >= 440

    # 4) 解答群
    choices = []
    choices_image = None
    if kaitou is not None:
        start = (rows[kaitou][0].page, rows[kaitou][0].y1)
        area_items = [i for i in q.items if (i.page, i.y0) >= start]
        labels = {l[0] for l in map(label_of, area_items) if l}
        # ア から順に続いている分だけ数える（表の中の別の文字を数えないため）
        n = 0
        while n < len(LABELS) and LABELS[n] in labels:
            n += 1
        labels = LABELS[:n]
        choices = [''] * (max(LABELS.index(l) for l in labels) + 1 if labels else 0)
        clips = []
        for pno in sorted({i.page for i in area_items}):
            top = start[1] if pno == start[0] else 50
            area = None
            for it in area_items:
                if it.page == pno:
                    r = pymupdf.Rect(it.x0, it.y0, it.x1, it.y1)
                    area = r if area is None else area | r
            for p, r in figures:
                if p == pno and r.y0 >= top - 2:
                    area |= r
            area.x0 = min(area.x0, 60)
            area.x1 = max(area.x1, doc[pno].rect.width - 50)
            path = os.path.join(img_dir, f'{qid}_choices_{pno}.png')
            save_clip(doc, pno, area + (-2, -4, 2, 4), path)
            clips.append(path)
        name = f'{qid}_choices.png'
        stitch(clips, os.path.join(img_dir, name))
        choices_image = name
    elif choice_start is not None:
        crows = rows[choice_start:]
        cur = None
        for row in crows:
            for it in row:
                lab = label_of(it)
                if lab and (not choices or LABELS.index(lab[0]) == len(choices)):
                    cur = {'label': lab[0], 'parts': [], 'x': it.x0}
                    if lab[1]:
                        cur['parts'].append((lab[1], it))
                    choices.append(cur)
                elif cur is not None:
                    cur['parts'].append((it.text.strip(), it))

        def join_parts(parts):
            out = ''
            for k, (t, it) in enumerate(parts):
                if k:
                    prev = parts[k - 1][1]
                    if abs(prev.y0 - it.y0) > 3:
                        # 次の行に続く: 右端まで書いてあれば折り返し、そうでなければ改行
                        out += '' if prev.x1 >= 440 else '\n'
                    elif it.x0 - prev.x1 > 6:
                        out += ' '
                out += t
            return out

        choices = [join_parts(c['parts']) for c in choices]
        # 解答群に図がある・中身が空のものは、解答群をまるごと画像にする
        choice_figs = [(p, r) for p, r in figures if stem_bottom and (p, r.y0) >= stem_bottom]
        if choice_figs or any(not c for c in choices):
            pno = rows[stem_end][0].page
            top = rows[stem_end][0].y0
            area = pymupdf.Rect(50, top - 4, doc[pno].rect.width - 40, top)
            for it in q.items:
                if it.page == pno and it.y0 >= top - 4:
                    area |= pymupdf.Rect(it.x0, it.y0, it.x1, it.y1)
            for p, r in choice_figs:
                if p == pno:
                    area |= r
            name = f'{qid}_choices.png'
            save_clip(doc, pno, area + (0, -2, 0, 4), os.path.join(img_dir, name))
            choices_image = name
    elif fig_labels:
        # 解答群が表（図）の中にある
        n = max(LABELS.index(l) for l in fig_labels) + 1
        choices = [''] * n
        last = blocks[-1] if blocks and blocks[-1]['type'] == 'image' else None
        if last:
            choices_image = last['src']
            blocks.pop()

    for b in blocks:
        b.pop('_wrap', None)
    return qid, blocks, choices, choices_image


def main(pdf_dir, out_dir):
    img_dir = os.path.join(out_dir, 'img')
    os.makedirs(img_dir, exist_ok=True)
    report = []
    index = []
    for prefix, exam_id, year, subject, source in EXAMS:
        qs_path = os.path.join(pdf_dir, prefix + '_qs.pdf')
        ans_path = os.path.join(pdf_dir, prefix + '_ans.pdf')
        if not os.path.exists(qs_path):
            report.append(f'{exam_id}: PDF がない')
            continue
        doc = pymupdf.open(qs_path)
        answers = read_answers(ans_path)
        out = []
        problems = []
        for q in split_questions(doc):
            qid, blocks, choices, choices_image = build(doc, q, exam_id, img_dir, answers.get(q.number))
            ans = answers.get(q.number)
            if ans is None:
                problems.append(f'問{q.number}: 正解がない')
                continue
            ans_index = LABELS.index(ans)
            if len(choices) <= ans_index:
                problems.append(f'問{q.number}: 解答群 {len(choices)}個なのに正解が{ans}')
            if not blocks:
                problems.append(f'問{q.number}: 問題文がない')
            question_text = '\n'.join(b['text'] for b in blocks if b['type'] != 'image')
            out.append({
                'id': qid,
                'exam': exam_id,
                'year': year,
                'subject': '科目' + subject,
                'number': q.number,
                'question': question_text,
                'blocks': blocks,
                'choices': choices,
                'choicesImage': choices_image,
                'answerIndex': ans_index,
                'source': f'出典：{source} 問{q.number}',
                'category': '',
                'topic': '',
                'explanation': '',
            })
        if len(out) != len(answers):
            problems.append(f'問題 {len(out)}問 / 解答例 {len(answers)}問')
        with open(os.path.join(out_dir, exam_id + '.json'), 'w', encoding='utf-8') as f:
            json.dump(out, f, ensure_ascii=False, indent=1)
        imgs = sum(1 for q in out for b in q['blocks'] if b['type'] == 'image') + sum(1 for q in out if q['choicesImage'])
        report.append(f'{exam_id}: {len(out)}問, 画像{imgs}枚' + ('' if not problems else '  ⚠ ' + ' / '.join(problems)))
        index.append({
            'id': exam_id,
            'file': exam_id + '.json',
            'year': year,
            'subject': '科目' + subject,
            # 一覧に出す名前（例: 令和7年度 公開問題 / サンプル問題）
            'title': re.sub(r'基本情報技術者試験 ?| 科目[AB]', '', source).strip(),
            'count': len(out),
        })
    # アプリはこの一覧を見て、どの問題ファイルを読むか決める（新しい年が上）
    index.sort(key=lambda e: (-e['year'], e['subject']))
    with open(os.path.join(out_dir, 'index.json'), 'w', encoding='utf-8') as f:
        json.dump({'exams': index}, f, ensure_ascii=False, indent=1)
    print('\n'.join(report))


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    main(sys.argv[1], sys.argv[2])
