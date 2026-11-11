import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../data/models/exam_goal.dart';
import '../providers/exam_goal_controller.dart';
import '../widgets/date_change_button.dart';
import '../widgets/goal_stepper.dart';
import '../widgets/settings_page.dart';

/// 試験日と1日の目標。試験日から逆算して、
/// 残りの日数 × 1日の目標 = 試験日までに解ける問題数 を表示する。
/// 保存するとホーム画面のカウントダウンにも反映される。
class ExamGoalScreen extends ConsumerWidget {
  const ExamGoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(examGoalProvider).when(
          loading: () => SettingsPage(title: '試験日と目標', children: [settingsLoading()]),
          error: (error, stackTrace) => SettingsPage(title: '試験日と目標', children: [settingsError()]),
          data: (goal) => _ExamGoalForm(initial: goal),
        );
  }
}

class _ExamGoalForm extends ConsumerStatefulWidget {
  const _ExamGoalForm({required this.initial});

  final ExamGoal initial;

  @override
  ConsumerState<_ExamGoalForm> createState() => _ExamGoalFormState();
}

class _ExamGoalFormState extends ConsumerState<_ExamGoalForm> {
  late DateTime _date = widget.initial.examDate;
  late int _goal = widget.initial.dailyTarget;
  bool _saving = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: now,
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: '試験日を選ぶ',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    await saveExamGoal(ref, ExamGoal(examDate: _date, dailyTarget: _goal));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存しました')));
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysUntil(_date);
    return SettingsPage(
      title: '試験日と目標',
      children: [
        const SectionLabel('試験日'),
        DateChangeButton(date: _date, daysLeft: days, onTap: _pickDate),
        const SizedBox(height: 26),
        const SectionLabel('1日の目標'),
        GoalStepper(value: _goal, onChanged: (v) => setState(() => _goal = v)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SettingsStyle.tint,
            borderRadius: BorderRadius.circular(SettingsStyle.smallRadius),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_graph_rounded, color: SettingsStyle.primaryText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'このペースで、試験日までに約${days * _goal}問',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: SettingsStyle.primaryText),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Center(child: PrimaryButton(label: '保存する', onPressed: _save, width: double.infinity)),
      ],
    );
  }
}

/// 今日から [date] までの日数（0より小さくならない）。
int _daysUntil(DateTime date) {
  final now = DateTime.now();
  // UTCで計算して、夏時間の日に1日ずれるのを防ぐ。
  final today = DateTime.utc(now.year, now.month, now.day);
  final target = DateTime.utc(date.year, date.month, date.day);
  final days = target.difference(today).inDays;
  return days < 0 ? 0 : days;
}
