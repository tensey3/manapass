import 'package:flutter/material.dart';

import '../providers/review_controller.dart';
import '../providers/review_data_source.dart';
import '../widgets/retry_all_button.dart';
import '../widgets/weak_area_card.dart';
import '../widgets/wrong_question_card.dart';

/// 復習画面（左サイドバーは app/shell 側。ここは中身だけ）。
///
/// 使い方:
///   ReviewScreen(
///     onRetryAll: (questionIds) => ...クイズ画面へ...,
///     onRetryOne: (questionId) => ...,
///   )
///   // 本物のデータを使う場合: ReviewDataSource を実装したクラスを dataSource に渡す
///   // onRetryAll / onRetryOne を渡さないと、解き直しボタンは押せない状態になる
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
            if (_c.error != null) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('読み込みに失敗しました\n${_c.error}', textAlign: TextAlign.center),
                  TextButton(onPressed: _c.load, child: const Text('再読み込み')),
                ]),
              );
            }
            final d = _c.data!;
            // 正答率の低い順に、苦手な分野を3つまで表示する
            final weakAreas = ([...d.weakAreas]..sort((a, b) => a.accuracy.compareTo(b.accuracy)))
                .take(3)
                .toList();
            return ListView(padding: const EdgeInsets.all(24), children: [
              Row(children: [
                const Expanded(
                  child: Text('復習', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ),
                RetryAllButton(
                  count: d.wrong.length,
                  onPressed: widget.onRetryAll == null
                      ? null
                      : () => widget.onRetryAll!(d.wrong.map((q) => q.id).toList()),
                ),
              ]),
              const SizedBox(height: 24),
              if (d.wrong.isEmpty && weakAreas.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: Text('復習する問題はありません 🎉')),
                ),
              if (weakAreas.isNotEmpty) ...[
                const Text('苦手分野', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  for (final a in weakAreas) WeakAreaCard(area: a),
                ]),
                const SizedBox(height: 28),
              ],
              if (d.wrong.isNotEmpty) ...[
                Text('間違えた問題（${d.wrong.length}）', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                for (final q in d.wrong)
                  WrongQuestionCard(
                    question: q,
                    onRetry: widget.onRetryOne == null ? null : () => widget.onRetryOne!(q.id),
                  ),
              ],
            ]);
          },
        ),
      );
}
