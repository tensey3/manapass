import 'package:flutter/material.dart';

import '../providers/review_controller.dart';
import '../providers/review_data_source.dart';
import '../widgets/retry_all_button.dart';
import '../widgets/weak_area_card.dart';
import '../widgets/wrong_question_tile.dart';

/// 復習画面（左サイドバーは app/shell 側。ここは中身だけ）。画面ID: review
///
/// 使い方:
///   ReviewScreen(
///     onRetryAll: (questionIds) => ...クイズ画面へ...,
///     onRetryOne: (questionId) => ...,
///   )
///   // 本物のデータを使う場合: ReviewDataSource を実装したクラスを dataSource に渡す
///   // onRetryAll / onRetryOne を渡さないと、解き直しボタンは押せない状態になる
///
/// 追加機能：苦手分野カードのタップで、その分野の問題だけに絞り込み（再タップで解除）。
/// 絞り込み中は「まとめて解き直す」の対象もその分野の問題だけになる。
/// 画面を下に引っ張ると復習データを再読み込みする。
class ReviewScreen extends StatefulWidget {
  final ReviewDataSource dataSource;
  final void Function(List<String> questionIds)? onRetryAll;
  final void Function(String questionId)? onRetryOne;
  const ReviewScreen({
    super.key,
    this.dataSource = const DemoReviewDataSource(),
    this.onRetryAll,
    this.onRetryOne,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final ReviewController _c = ReviewController(widget.dataSource)..load();

  /// 苦手分野での絞り込み（null = 絞り込みなし）
  String? _filter;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        if (_c.loading && _c.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_c.error != null && _c.data == null) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('読み込みに失敗しました\n${_c.error}', textAlign: TextAlign.center),
              TextButton(onPressed: _c.load, child: const Text('再読み込み')),
            ]),
          );
        }
        final d = _c.data!;
        final t = Theme.of(context).textTheme;
        // 正答率の低い順に、苦手な分野を3つまで表示する
        final weakAreas =
        ([...d.weakAreas]..sort((a, b) => a.accuracy.compareTo(b.accuracy)))
            .take(3)
            .toList();
        // 絞り込み適用後の「間違えた問題」。まとめて解き直す対象もこれ。
        final visible = _filter == null
            ? d.wrong
            : d.wrong.where((q) => q.category == _filter).toList();

        return RefreshIndicator(
          onRefresh: _c.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              // No.8 画面タイトル / No.9 復習問題数
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('復習',
                      style: t.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Text('${d.wrong.length}問',
                      style: t.bodyMedium
                          ?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 16),
              // No.10 まとめて解き直す
              RetryAllButton(
                count: visible.length,
                onPressed: widget.onRetryAll == null
                    ? null
                    : () => widget.onRetryAll!(
                    visible.map((q) => q.id).toList()),
              ),
              const SizedBox(height: 24),
              if (d.wrong.isEmpty && weakAreas.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: Text('復習する問題はありません 🎉')),
                ),
              // No.11〜20 苦手分野
              if (weakAreas.isNotEmpty) ...[
                Text('苦手分野',
                    style: t.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                for (final a in weakAreas) ...[
                  WeakAreaCard(
                    area: a,
                    selected: _filter == a.category,
                    onTap: () => setState(() =>
                    _filter = _filter == a.category ? null : a.category),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 14),
              ],
              // No.21〜30 間違えた問題
              if (d.wrong.isNotEmpty) ...[
                Row(children: [
                  Text('間違えた問題',
                      style: t.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (_filter != null)
                    InputChip(
                      label: Text('$_filter で絞り込み中'),
                      onDeleted: () => setState(() => _filter = null),
                    ),
                ]),
                const SizedBox(height: 10),
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('この分野の間違えた問題はありません',
                          style: t.bodyMedium
                              ?.copyWith(color: Colors.grey.shade600)),
                    ),
                  ),
                for (final q in visible) ...[
                  WrongQuestionTile(
                    question: q,
                    onTap: widget.onRetryOne == null
                        ? null
                        : () => widget.onRetryOne!(q.id),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        );
      },
    ),
  );
}
