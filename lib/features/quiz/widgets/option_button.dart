import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 選択肢の記号（ア〜コ）
const choiceLabels = ['ア', 'イ', 'ウ', 'エ', 'オ', 'カ', 'キ', 'ク', 'ケ', 'コ', 'サ', 'シ', 'ス', 'セ', 'ソ'];

String choiceLabel(int index) => index < choiceLabels.length ? choiceLabels[index] : '${index + 1}';

/// 選択肢の状態。色で表す：青 = 選んだ、緑 = 正解、赤 = 選んだけど不正解。
enum ChoiceState { idle, selected, correct, wrong, dimmed }

const _correctColor = AppColors.success;
const _wrongColor = Color(0xFFE5484D);

(Color border, Color fill, Color circle, IconData? icon) _colors(ChoiceState state) => switch (state) {
      ChoiceState.idle || ChoiceState.dimmed => (AppColors.track, Colors.white, AppColors.track, null),
      ChoiceState.selected => (AppColors.primary, AppColors.menuSelectedBg, AppColors.primary, null),
      ChoiceState.correct => (_correctColor, const Color(0xFFEAF8EC), _correctColor, Icons.check_circle_rounded),
      ChoiceState.wrong => (_wrongColor, const Color(0xFFFDECEC), _wrongColor, Icons.cancel_rounded),
    };

/// 文章の選択肢（ア + 文）。
class OptionButton extends StatelessWidget {
  const OptionButton({super.key, required this.label, required this.text, required this.state, this.onTap, this.content});

  final String label;
  final String text;
  final Widget? content; // ふりがな付きの文など。null なら text をそのまま出す
  final ChoiceState state;
  final VoidCallback? onTap; // null = もう変えられない

  @override
  Widget build(BuildContext context) {
    final (border, fill, circle, icon) = _colors(state);
    final circleText = state == ChoiceState.idle || state == ChoiceState.dimmed ? AppColors.textMuted : Colors.white;
    final radius = BorderRadius.circular(14);
    return Opacity(
      opacity: state == ChoiceState.dimmed ? 0.55 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(color: fill, borderRadius: radius, border: Border.all(color: border, width: 2)),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _LabelCircle(label: label, color: circle, textColor: circleText),
                  const SizedBox(width: 14),
                  Expanded(child: content ?? Text(text, style: const TextStyle(fontSize: 16, height: 1.5))),
                  if (icon != null) ...[const SizedBox(width: 8), Icon(icon, color: border, size: 26)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 解答群が画像のときの、記号だけのボタン（ア イ ウ …）。
class LabelOnlyButton extends StatelessWidget {
  const LabelOnlyButton({super.key, required this.label, required this.state, this.onTap});

  final String label;
  final ChoiceState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (border, fill, _, icon) = _colors(state);
    final textColor = switch (state) {
      ChoiceState.selected => AppColors.primary,
      ChoiceState.correct => _correctColor,
      ChoiceState.wrong => _wrongColor,
      _ => AppColors.textStrong,
    };
    final radius = BorderRadius.circular(14);
    return Opacity(
      opacity: state == ChoiceState.dimmed ? 0.55 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 64,
        height: 56,
        decoration: BoxDecoration(color: fill, borderRadius: radius, border: Border.all(color: border, width: 2)),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Center(
              child: icon == null
                  ? Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                        Icon(icon, color: border, size: 18),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabelCircle extends StatelessWidget {
  const _LabelCircle({required this.label, required this.color, required this.textColor});

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
      );
}
