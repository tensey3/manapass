import 'package:flutter/material.dart';

import '../providers/progress_controller.dart';
import 'progress_surface.dart';

/// 分野別の正答率。バーの色は正答率で変わる（緑・オレンジ・赤）。
class CategoryAccuracyList extends StatelessWidget {
  const CategoryAccuracyList({super.key, required this.subjects});

  final List<SubjectAccuracy> subjects;

  @override
  Widget build(BuildContext context) => Surface(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: [
          for (var i = 0; i < subjects.length; i++)
            _SubjectRow(subject: subjects[i], last: i == subjects.length - 1),
        ]),
      );
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.subject, required this.last});

  final SubjectAccuracy subject;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final percent = subject.percent;
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: ProgressStyle.line)),
      ),
      child: Row(children: [
        SizedBox(
          width: 100,
          child: Text(subject.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: percent == null
              ? const Text('まだ解いていません', style: TextStyle(fontSize: 11, color: ProgressStyle.muted))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 9,
                    backgroundColor: ProgressStyle.track,
                    color: ProgressStyle.forAccuracy(percent),
                  ),
                ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            percent == null ? '—' : '$percent%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, color: ProgressStyle.muted),
          ),
        ),
      ]),
    );
  }
}
