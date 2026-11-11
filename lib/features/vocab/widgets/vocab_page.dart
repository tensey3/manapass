import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/theme/app_theme.dart';

/// 単語帳で使う色と角の丸さ。
abstract final class VocabStyle {
  static const primary = AppColors.primary;
  static const ink = AppColors.textStrong;
  static const muted = AppColors.textMuted;
  static const correct = AppColors.success;
  static const tint = AppColors.menuSelectedBg;
  static const primaryText = AppColors.menuSelectedText;
  static const line = Color(0xFFE4E8EE);
  static const soft = Color(0xFFF2F5F9);
  static const correctText = Color(0xFF1F8A3A);
  static const warning = Color(0xFFF08C00);
  static const warningText = Color(0xFFB35C00);

  static const cardRadius = 22.0;
  static const buttonRadius = 16.0;
  static const smallRadius = 14.0;

  static const cardShadow = [
    BoxShadow(color: Color(0x0F0F1928), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x380F1928), offset: Offset(0, 10), blurRadius: 24, spreadRadius: -10),
  ];
}

/// 単語帳の各ページの枠：タイトル（と戻るボタン）＋中身。PCでは中央に読みやすい幅で表示。
class VocabPage extends StatelessWidget {
  const VocabPage({
    super.key,
    required this.children,
    this.title,
    this.trailing,
    this.showBack = true,
  });

  final String? title;
  final String? trailing; // タイトルの後ろの小さいグレーの文字（例：8語）
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (showBack) ...[
                      IconButton(
                        onPressed: () => vocabBack(context),
                        tooltip: '戻る',
                        icon: const Icon(Icons.arrow_back_rounded, color: VocabStyle.ink),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (title != null)
                      Text(title!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    if (trailing != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        trailing!,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: VocabStyle.muted),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 前のページに戻る。URLで直接開いたときは単語帳の一覧へ。
void vocabBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(Routes.vocab);
  }
}

/// 白いカード（影つき）。[onTap] があれば押せる。
class VocabCard extends StatelessWidget {
  const VocabCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(22)});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(VocabStyle.cardRadius);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: radius, boxShadow: VocabStyle.cardShadow),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// 白い枠のボタン（例：単語帳から外す、まだ）。
class VocabOutlinedButton extends StatelessWidget {
  const VocabOutlinedButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        style: OutlinedButton.styleFrom(
          foregroundColor: VocabStyle.primaryText,
          backgroundColor: Colors.white,
          side: const BorderSide(color: VocabStyle.line, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VocabStyle.buttonRadius)),
        ),
      ),
    );
  }
}

/// 色つきのボタン（例：復習する、覚えた）。[onPressed] が null なら押せない（グレー）。
class VocabFilledButton extends StatelessWidget {
  const VocabFilledButton({super.key, required this.label, required this.onPressed, this.icon, this.color});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final background = color ?? VocabStyle.primary;
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: Colors.white,
          disabledBackgroundColor: VocabStyle.line,
          disabledForegroundColor: VocabStyle.muted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VocabStyle.buttonRadius)),
        ),
      ),
    );
  }
}
