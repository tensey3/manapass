import 'package:flutter/material.dart';

const ink = Color(0xFF374151);
const muted = Color(0xFF8C97A8);
const blue = Color(0xFF3185DE);
const line = Color(0xFFEDF0F5);

/// The parent app shell already provides the navigation sidebar.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 700;
      return SingleChildScrollView(
        padding: EdgeInsets.all(wide ? 28 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('進捗', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                SizedBox(height: 20),
                SummaryCards(),
                SizedBox(height: 26),
                SectionTitle('今週の学習時間'),
                SizedBox(height: 12),
                Surface(child: WeeklyChart()),
                SizedBox(height: 26),
                SectionTitle('分野別の正答率'),
                SizedBox(height: 12),
                SubjectProgress(),
                SizedBox(height: 26),
                SectionTitle('模擬試験の記録'),
                SizedBox(height: 12),
                ExamHistory(),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    },
  );
}

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

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800));
}

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final columns = constraints.maxWidth < 520 ? 2 : 4;
    final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
    const values = ['57%', '2時間', '7', '3'];
    const labels = ['正答率', '今週の学習時間', '解いた問題', '復習が必要'];
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: List.generate(4, (i) => SizedBox(
        width: width,
        child: Surface(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(values[i], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(labels[i], style: const TextStyle(color: muted, fontSize: 11)),
          ]),
        ),
      )),
    );
  });
}

class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key});

  @override
  Widget build(BuildContext context) {
    const minutes = [45, 30, 63, 0, 0, 0, 0];
    const days = ['月', '火', '水', '木', '金', '土', '日'];
    return SizedBox(
      height: 210,
      child: Column(children: [
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(7, (i) {
            return Expanded(
              child: Tooltip(
                message: '${days[i]}曜日：${minutes[i]}分',
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (i == 3) const Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text('0分', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  Container(
                    width: 20,
                    height: minutes[i] * 2.4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFAFD4FF),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                ]),
              ),
            );
          })),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFDCE4EE)),
        const SizedBox(height: 10),
        Row(children: List.generate(7, (i) => Expanded(
          child: Text(days[i], textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: i == 3 ? ink : muted, fontWeight: i == 3 ? FontWeight.bold : FontWeight.normal)),
        ))),
      ]),
    );
  }
}

class SubjectProgress extends StatelessWidget {
  const SubjectProgress({super.key});

  @override
  Widget build(BuildContext context) => const Surface(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Column(children: [
      SubjectRow('ネットワーク', 0, blue),
      SubjectRow('アルゴリズム', 33, Color(0xFFFF5252)),
      SubjectRow('基礎理論', 67, Color(0xFFF59E0B)),
      SubjectRow('データベース', 75, Color(0xFF32C451)),
      SubjectRow('セキュリティ', 100, Color(0xFF32C451)),
      SubjectRow('マネジメント', null, blue, last: true),
    ]),
  );
}

class SubjectRow extends StatelessWidget {
  const SubjectRow(this.label, this.percent, this.color, {this.last = false, super.key});
  final String label;
  final int? percent;
  final Color color;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 52),
    decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: line))),
    child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
      Expanded(
        child: percent == null
            ? const Text('まだ解いていません', style: TextStyle(fontSize: 11, color: muted))
            : ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: percent! / 100, minHeight: 9, backgroundColor: const Color(0xFFF0F3F8), color: color),
        ),
      ),
      SizedBox(width: 48, child: Text(percent == null ? '—' : '$percent%', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: muted))),
      const SizedBox(width: 6),
      const Icon(Icons.chevron_right, size: 16, color: muted),
    ]),
  );
}

class ExamHistory extends StatelessWidget {
  const ExamHistory({super.key});
  @override
  Widget build(BuildContext context) => const Surface(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Column(children: [
      ExamRow('10月10日・科目A', '11/08 12:59', 70),
      Divider(height: 1, color: line),
      ExamRow('10月6日・科目A', '10/06 13:59', 60),
    ]),
  );
}

class ExamRow extends StatelessWidget {
  const ExamRow(this.title, this.date, this.score, {super.key});
  final String title;
  final String date;
  final int score;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(date, style: const TextStyle(fontSize: 10, color: muted)),
      ])),
      const Icon(Icons.check_circle, color: Color(0xFF32C451), size: 18),
      const SizedBox(width: 5),
      Text('$score%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  );
}
