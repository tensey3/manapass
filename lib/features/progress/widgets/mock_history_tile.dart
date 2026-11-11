import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/progress_sample.dart';
import 'progress_surface.dart';

/// 模擬試験の記録（新しい順）。
class MockHistoryList extends StatelessWidget {
  const MockHistoryList({super.key, required this.results});

  final List<MockResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Surface(
        child: Text('まだ模擬試験の記録がありません', style: TextStyle(fontSize: 13, color: ProgressStyle.muted)),
      );
    }
    return Surface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(children: [
        for (var i = 0; i < results.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: ProgressStyle.line),
          MockHistoryTile(result: results[i]),
        ],
      ]),
    );
  }
}

/// 模擬試験1回分：日付と科目、正解数と時間、合格の目安（60%）に届いたか。
class MockHistoryTile extends StatelessWidget {
  const MockHistoryTile({super.key, required this.result});

  final MockResult result;

  @override
  Widget build(BuildContext context) {
    final time = result.time;
    final seconds = (time.inSeconds % 60).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${DateFormat('M月d日(E)', 'ja').format(result.date)}・科目${result.subject}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              '${result.correct}/${result.total}問正解・${time.inMinutes}分$seconds秒',
              style: const TextStyle(fontSize: 10, color: ProgressStyle.muted),
            ),
          ]),
        ),
        Tooltip(
          message: result.passed ? '合格の目安（60%）に届いています' : '合格の目安（60%）に届いていません',
          child: Icon(
            result.passed ? Icons.check_circle : Icons.cancel,
            color: result.passed ? ProgressStyle.green : ProgressStyle.red,
            size: 18,
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 40,
          child: Text(
            '${result.percent}%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    );
  }
}
