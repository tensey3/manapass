import 'package:flutter/material.dart';

import 'settings_page.dart';

/// ふりがなの見本。漢字の上に読みを表示する。
/// 書き方：[排他制御|はいたせいぎょ] = 読みつきの言葉、それ以外はそのままの文字。
class FuriganaPreview extends StatelessWidget {
  const FuriganaPreview(
    this.markup, {
    super.key,
    required this.showFurigana,
    required this.rubyScale,
    this.size = 18,
    this.style,
  });

  final String markup;
  final bool showFurigana;
  final double rubyScale; // 本文に対するふりがなの大きさ
  final double size;
  final TextStyle? style; // フォントや色を変えたいとき（見た目の見本など）

  @override
  Widget build(BuildContext context) {
    final baseStyle = (style ?? const TextStyle()).copyWith(
      fontSize: size,
      height: 1.45,
      color: style?.color ?? SettingsStyle.ink,
    );
    final rubyStyle = baseStyle.copyWith(
      fontSize: size * rubyScale,
      fontWeight: FontWeight.w700,
      color: SettingsStyle.muted,
      height: 1,
    );
    final segments = _parse(markup);
    // 読みがある行は、すべての文字の上に同じ高さの余白を取って、文字の高さをそろえる。
    final rubySpace = showFurigana && segments.any((s) => s.reading != null) ? size * (rubyScale + 0.12) : 0.0;

    Widget piece(String text, {String? reading}) {
      final base = Column(
        mainAxisSize: MainAxisSize.min,
        children: [SizedBox(height: rubySpace), Text(text, style: baseStyle)],
      );
      if (!showFurigana || reading == null) return base;
      // 読みが漢字より長いとき（例：行 → おこな）は、となりの文字の上にはみ出して表示する。
      return Stack(
        clipBehavior: Clip.none,
        children: [
          base,
          Positioned(
            top: 0,
            left: -size * 2,
            right: -size * 2,
            child: Text(reading, style: rubyStyle, maxLines: 1, softWrap: false, textAlign: TextAlign.center),
          ),
        ],
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      runSpacing: size * 0.2,
      children: [
        for (final s in segments)
          if (s.reading != null) piece(s.text, reading: s.reading) else ..._splitForWrap(s.text).map(piece),
      ],
    );
  }
}

class _Segment {
  const _Segment(this.text, [this.reading]);

  final String text;
  final String? reading;
}

final _bracket = RegExp(r'\[([^\]|]+)(?:\|([^\]]+))?\]');

List<_Segment> _parse(String source) {
  final out = <_Segment>[];
  var last = 0;
  for (final m in _bracket.allMatches(source)) {
    if (m.start > last) out.add(_Segment(source.substring(last, m.start)));
    out.add(_Segment(m[1]!, m[2]));
    last = m.end;
  }
  if (last < source.length) out.add(_Segment(source.substring(last)));
  return out;
}

// 日本語はどの文字の間でも改行できるので、1文字ずつに分ける。
// 英数字はまとめたまま、句読点は前の文字にくっつけて行の先頭に来ないようにする。
final _unit = RegExp(r'[A-Za-z0-9_.,/%:+=\-]+|.', unicode: true);
const _openers = '（「『(';
const _closers = '、。，．）」』)！？';

List<String> _splitForWrap(String text) {
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
