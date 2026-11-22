import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/question_repository.dart';
import '../../quiz/screens/question_answer_screen.dart';
import '../providers/question_list_controller.dart';

/// 問題画面：ランダムクイズ・模擬試験・写真から追加 と、年度別の問題（科目A / 科目B）。
class QuestionListScreen extends ConsumerWidget {
  const QuestionListScreen({super.key});

  static const _subjects = ['科目A', '科目B'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subject = ref.watch(selectedSubjectProvider);
    final exams = ref.watch(examsProvider);
    // 解答の記録が読めなくても（未ログイン・通信エラー）一覧は出す
    final records = ref.watch(answerRecordsProvider).valueOrNull ?? const <String, AnswerRecord>{};

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(answerRecordsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('問題', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 20),
            Row(
              children: [
                _ActionButton(icon: Icons.shuffle_rounded, label: 'ランダムクイズ', onTap: () => context.push(Routes.randomQuiz)),
                const SizedBox(width: 16),
                _ActionButton(icon: Icons.timer, label: '模擬試験', onTap: () => context.push(Routes.mockExam)),
                const SizedBox(width: 16),
                _ActionButton(icon: Icons.camera_alt, label: '写真から追加', onTap: () => context.push(Routes.addFromPhoto)),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 12,
              spacing: 12,
              children: [
                const Text('年度別', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                _SubjectTabs(
                  subjects: _subjects,
                  selected: subject,
                  onChanged: (s) => ref.read(selectedSubjectProvider.notifier).state = s,
                ),
              ],
            ),
            const SizedBox(height: 16),
            exams.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Column(
                children: [
                  const Text('問題を読み込めませんでした'),
                  TextButton(onPressed: () => ref.invalidate(examsProvider), child: const Text('再読み込み')),
                ],
              ),
              data: (all) => Column(
                children: [
                  for (final exam in all.where((e) => e.subject == subject))
                    _ExamCard(
                      exam: exam,
                      solved: solvedCount(exam.id, records),
                      onTap: () => _open(context, ref, exam, records),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// まだ解いていない最初の問題から始める（全部解いていたら1問目から）。
  Future<void> _open(BuildContext context, WidgetRef ref, ExamInfo exam, Map<String, AnswerRecord> records) async {
    final questions = await ref.read(examQuestionsProvider(exam.id).future);
    if (!context.mounted || questions.isEmpty) return;
    var start = questions.indexWhere((q) => !records.containsKey(q.id.toString()));
    if (start < 0) start = 0;
    await openQuiz(context, ref, title: '${exam.title} ${exam.subject}', questions: questions, startIndex: start);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.blue[600], size: 24),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 科目A / 科目B の切り替え
class _SubjectTabs extends StatelessWidget {
  const _SubjectTabs({required this.subjects, required this.selected, required this.onChanged});

  final List<String> subjects;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      height: 40,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          for (final s in subjects)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(s),
                child: Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: s == selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: s == selected
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                        : const [],
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: s == selected ? Colors.blue : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 1回分の試験のカード：名前・問題数・解いた数
class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, required this.solved, required this.onTap});

  final ExamInfo exam;
  final int solved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = exam.count;
    final done = total > 0 && solved >= total;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.folder, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('${exam.subject}・$total問', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$solved/$total',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total > 0 ? (solved / total).clamp(0.0, 1.0) : 0,
                          backgroundColor: Colors.grey[200],
                          color: done ? AppColors.success : Colors.blue,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
