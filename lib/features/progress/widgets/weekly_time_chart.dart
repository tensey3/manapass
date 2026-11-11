import 'package:flutter/material.dart';

import 'progress_surface.dart';

/// 今週の学習時間の棒グラフ（月〜日）。
/// 今日の棒は濃い色で、上に時間を表示する。どの棒もマウスを乗せる / 長押しで時間が見える。
/// 今日より後の日は、まだ棒を出さない。
class WeeklyTimeChart extends StatelessWidget {
  const WeeklyTimeChart({super.key, required this.minutes, required this.todayIndex});

  final List<int?> minutes; // 月〜日。null = まだ来ていない日
  final int todayIndex; // 0 = 月曜日

  static const _days = ['月', '火', '水', '木', '金', '土', '日'];
  static const _barArea = 150.0; // 一番長い棒の高さ

  @override
  Widget build(BuildContext context) {
    final values = minutes.whereType<int>();
    // 少ない日が大きく見えすぎないように、高さの基準は最低60分にする。
    final scale = values.fold(60, (a, b) => b > a ? b : a);

    return SizedBox(
      height: 210,
      child: Column(children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++) Expanded(child: _bar(i, scale)),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFDCE4EE)),
        const SizedBox(height: 10),
        Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Text(
                _days[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: i == todayIndex ? ProgressStyle.ink : ProgressStyle.muted,
                  fontWeight: i == todayIndex ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _bar(int i, int scale) {
    final value = minutes[i];
    if (value == null) return const SizedBox.shrink();
    final isToday = i == todayIndex;
    return Tooltip(
      message: '${_days[i]}曜日：${formatMinutes(value)}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isToday)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                formatMinutes(value),
                maxLines: 1,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          Container(
            width: 20,
            height: _barArea * value / scale,
            decoration: BoxDecoration(
              color: isToday ? ProgressStyle.blue : ProgressStyle.lightBlue,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }
}
