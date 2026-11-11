import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'settings_page.dart';

/// 試験日のカード。押すと日付を選べる。
class DateChangeButton extends StatelessWidget {
  const DateChangeButton({super.key, required this.date, required this.daysLeft, required this.onTap});

  final DateTime date;
  final int daysLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SettingsStyle.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.event_rounded, color: SettingsStyle.primary, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat.yMMMEd('ja').format(date),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'あと$daysLeft日',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: SettingsStyle.muted),
                      ),
                    ],
                  ),
                ),
                const Text(
                  '変更',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: SettingsStyle.primaryText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
