import 'package:flutter/material.dart';

import '../../data/models/question.dart';
import '../theme/app_theme.dart';

/// ふりがな付きの文。漢字の上に読みを出す。辞書にある単語はタップできる（点線の下線）。
/// 文のデータは tool/questions/add_furigana.py が作った単語の並び（RubyToken）。
class FuriganaText extends StatelessWidget {
  const FuriganaText(
    this.tokens, {
    super.key,
    required this.showFurigana,
    this.rubyScale = 0.5,
    this.size = 17,
    this.onTapWord,
  });

  final List<RubyToken> tokens;
  final bool showFurigana;
  final double rubyScale; // 本文に対するふりがなの大きさ
  final double size;
  final ValueChanged<String>? onTapWord; // 押した単語の辞書の見出し

  @override
  Widget build(BuildContext context) {
    // アプリのフォント（テーマ）に合わせる。幅を測るときも同じ字の形で測る
    final inherited = DefaultTextStyle.of(context).style;
    final baseStyle = inherited.merge(TextStyle(fontSize: size, height: 1.45, color: AppColors.textStrong));
    final linkStyle = baseStyle.copyWith(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: AppColors.primary.withValues(alpha: 0.6),
    );
    final rubyStyle = inherited.merge(TextStyle(
      fontSize: size * rubyScale,
      fontWeight: FontWeight.w700,
      color: AppColors.textMuted,
      height: 1,
    ));
    // 読みがある文は、すべての文字の上に同じ高さの余白を取って、行の高さをそろえる
    final rubySpace =
        showFurigana && tokens.any((t) => t.parts?.any((p) => p.$2 != null) ?? false) ? size * (rubyScale + 0.15) : 0.0;

    Widget piece(String text, {String? reading, String? key}) {
      Widget w = Column(
        mainAxisSize: MainAxisSize.min,
        children: [SizedBox(height: rubySpace), Text(text, style: key == null ? baseStyle : linkStyle)],
      );
      if (showFurigana && reading != null) {
        // 読みと漢字を縦に並べる。幅は長いほうに合わせる（例：小数 → しょうすう のときは読みの幅）。
        // こうすると、となりの読みと重ならない。フォントが後から読み込まれても自動で合う。
        w = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: rubySpace,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [Text(reading, style: rubyStyle, maxLines: 1, softWrap: false)],
              ),
            ),
            Text(text, style: key == null ? baseStyle : linkStyle, maxLines: 1, softWrap: false),
          ],
        );
      }
      if (key != null && onTapWord != null) {
        w = MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => onTapWord!(key), child: w),
        );
      }
      return w;
    }

    // 改行（\n）ごとに行を分けて、行ごとに折り返す
    final lines = <List<Widget>>[[]];
    void addPlain(String text) {
      for (final c in splitForWrap(text)) {
        if (c == '\n') {
          lines.add([]);
        } else {
          lines.last.add(piece(c));
        }
      }
    }

    for (final t in tokens) {
      final parts = t.parts;
      if (parts != null) {
        for (final (text, reading) in parts) {
          // 読みのない部分（送りがな）は、行の折り返しのために1文字ずつにする
          if (reading == null && t.key == null) {
            addPlain(text);
          } else {
            lines.last.add(piece(text, reading: reading, key: t.key));
          }
        }
      } else if (t.key != null) {
        lines.last.add(piece(t.text, key: t.key));
      } else {
        addPlain(t.text);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            runSpacing: size * 0.25,
            children: line.isEmpty ? [piece(' ')] : line,
          ),
      ],
    );
  }
}

// 日本語はどの文字の間でも改行できるので、1文字ずつに分ける。
// 英数字はまとめたまま、句読点は前の文字にくっつけて行の先頭に来ないようにする。
// 改行（\n）は、そこで行を変える。
final _unit = RegExp(r'\n|[A-Za-z0-9_.,/%:+=\-−]+|.', unicode: true);
const _openers = '（「『(“';
const _closers = '、。，．）」』)！？”';

List<String> splitForWrap(String text) {
  final out = <String>[];
  var prefix = '';
  for (final m in _unit.allMatches(text)) {
    final piece = m[0]!;
    if (_openers.contains(piece)) {
      prefix += piece;
    } else if (_closers.contains(piece) && out.isNotEmpty && prefix.isEmpty) {
      out[out.length - 1] += piece;
    } else {
      out.add(prefix + piece);
      prefix = '';
    }
  }
  if (prefix.isNotEmpty) out.add(prefix);
  return out;
}
