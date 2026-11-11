import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 見た目の設定で選べるテーマカラー。
/// main = ボタンや強調、accent = 進捗バーなど。
class ThemePreset {
  const ThemePreset(this.id, this.name, this.primary, this.accent);

  final String id;
  final String name;
  final Color primary;
  final Color accent;
}

const themePresets = [
  ThemePreset('blue', 'ブルー', Color(0xFF3D9BFF), Color(0xFF3DBE4A)),
  ThemePreset('green', 'グリーン', Color(0xFF2BAE66), Color(0xFF3D9BFF)),
  ThemePreset('orange', 'オレンジ', Color(0xFFF57C00), Color(0xFF3DBE4A)),
  ThemePreset('purple', 'パープル', Color(0xFF8B5CF6), Color(0xFFEC4899)),
  ThemePreset('pink', 'ピンク', Color(0xFFE8487A), Color(0xFF8B5CF6)),
  ThemePreset('teal', 'ティール', Color(0xFF0E9F9F), Color(0xFFF5A524)),
];

ThemePreset themePresetOf(String id) =>
    themePresets.firstWhere((t) => t.id == id, orElse: () => themePresets.first);

/// 選べるフォント（すべて Google Fonts の無料フォント）。
const fontFamilies = ['Zen Maru Gothic', 'M PLUS Rounded 1c', 'Kiwi Maru', 'BIZ UDPGothic'];

/// フォント名から文字のスタイルを作る。
/// 名前で探さず直接呼ぶので、この4つのフォントだけがアプリに入る。
TextStyle fontStyle(
  String family, {
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
}) {
  return switch (family) {
    'M PLUS Rounded 1c' =>
      GoogleFonts.mPlusRounded1c(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height),
    'Kiwi Maru' => GoogleFonts.kiwiMaru(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height),
    'BIZ UDPGothic' =>
      GoogleFonts.bizUDPGothic(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height),
    _ => GoogleFonts.zenMaruGothic(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height),
  };
}
