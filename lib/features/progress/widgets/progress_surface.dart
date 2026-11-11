import 'package:flutter/material.dart';

/// 進捗画面で使う色。
abstract final class ProgressStyle {
  static const ink = Color(0xFF374151);
  static const muted = Color(0xFF8C97A8);
  static const blue = Color(0xFF3185DE);
  static const lightBlue = Color(0xFFAFD4FF);
  static const line = Color(0xFFEDF0F5);
  static const track = Color(0xFFF0F3F8);
  static const green = Color(0xFF32C451);
  static const orange = Color(0xFFF59E0B);
  static const red = Color(0xFFFF5252);

  /// 正答率の色：70%以上は緑、50%以上はオレンジ、それより下は赤。
  static Color forAccuracy(int percent) => percent >= 70 ? green : (percent >= 50 ? orange : red);
}

/// 白いカード（影つき）。
class Surface extends StatelessWidget {
  const Surface({required this.child, this.padding = const EdgeInsets.all(20), super.key});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, 5))],
        ),
        child: child,
      );
}

/// 各まとまりの見出し（例：今週の学習時間）。
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800));
}

/// 分を「2時間40分」「45分」「2時間」のように表示する。
String formatMinutes(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return '$m分';
  return m == 0 ? '$h時間' : '$h時間$m分';
}
