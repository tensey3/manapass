import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/question.dart';
import 'option_button.dart';

/// 問題文：出典・文章・プログラム・図（画像）を上から順に出す。
class QuestionBody extends StatelessWidget {
  const QuestionBody({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    // 古い形のデータ（blocks がない）は、問題文の文字だけ出す
    final blocks = question.blocks.isNotEmpty
        ? question.blocks
        : [QuestionBlock(type: 'text', text: question.questionText)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (question.source != null) ...[
          // IPA の決まり：問題には出典を書く
          Text(question.source!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
        ],
        for (final block in blocks) ...[
          if (block.isImage)
            QuestionImage(assetPath: block.assetPath!)
          else if (block.isCode)
            _CodeBlock(text: block.text)
          else
            Text(block.text, style: const TextStyle(fontSize: 17, height: 1.7)),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

/// 解答群：文章の選択肢、または「解答群の画像 + 記号ボタン」。
class ChoicesView extends StatelessWidget {
  const ChoicesView({super.key, required this.question, required this.stateOf, this.onSelect});

  final Question question;
  final ChoiceState Function(int index) stateOf;
  final ValueChanged<int>? onSelect; // null = もう選べない

  @override
  Widget build(BuildContext context) {
    final count = question.choices.length;
    if (question.choicesImagePath != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('解答群', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          QuestionImage(assetPath: question.choicesImagePath!),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < count; i++)
                LabelOnlyButton(
                  label: choiceLabel(i),
                  state: stateOf(i),
                  onTap: onSelect == null ? null : () => onSelect!(i),
                ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OptionButton(
              label: choiceLabel(i),
              text: question.choices[i],
              state: stateOf(i),
              onTap: onSelect == null ? null : () => onSelect!(i),
            ),
          ),
      ],
    );
  }
}

/// 図・表の画像。タップすると大きくして見られる（スマホで小さい字を読むため）。
class QuestionImage extends StatelessWidget {
  const QuestionImage({super.key, required this.assetPath});

  final String assetPath;

  // 画像は 200dpi で切り出してあるので、文章の字と同じくらいの大きさに見えるように縮める
  // （画面より大きいときは、画面の幅に合わせてさらに縮む）
  static const _scale = 1.8;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => _openZoom(context),
        child: MouseRegion(
          cursor: SystemMouseCursors.zoomIn,
          child: Image.asset(
            assetPath,
            scale: _scale,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) =>
                const Text('（図を表示できませんでした）', style: TextStyle(color: AppColors.textMuted)),
          ),
        ),
      ),
    );
  }

  void _openZoom(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              maxScale: 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(assetPath, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                tooltip: '閉じる',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// プログラムの文字の形。等幅（全角も半角もそろう）フォントで、IPA の問題冊子と同じように字下げが見えるようにする。
/// フォントはネットから読むので、テストではふつうの TextStyle に差しかえる。
TextStyle Function() codeTextStyle =
    () => GoogleFonts.bizUDGothic(fontSize: 15, height: 1.6, color: AppColors.textStrong);

/// 行の頭の半角スペース2つを全角スペース1つにする。
/// 等幅フォントでは同じ幅なので見た目は変わらず、フォントが読めなかったときも字下げがはっきり見える。
String _indentWide(String code) => code.split('\n').map((line) {
      final spaces = line.length - line.replaceFirst(RegExp(r'^ +'), '').length;
      final wide = '　' * (spaces ~/ 2) + ' ' * (spaces % 2);
      return wide + line.substring(spaces);
    }).join('\n');

/// プログラム（擬似言語）。字下げが大事なので、そのまま出す。横に長いときは横にスクロール。
class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.track),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(_indentWide(text), softWrap: false, style: codeTextStyle()),
      ),
    );
  }
}
