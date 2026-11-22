import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/question.dart';
import '../../../data/repositories/question_repository.dart';
import '../../quiz/screens/question_answer_screen.dart';

/// ランダムクイズ：科目と問題数を選んで、全部の問題からランダムに出す。
/// 復習画面の「解き直す」から来たとき（questionIds あり）は、その問題をすぐ出す。
class RandomQuizScreen extends ConsumerStatefulWidget {
  const RandomQuizScreen({super.key, this.questionIds});

  final List<String>? questionIds;

  @override
  ConsumerState<RandomQuizScreen> createState() => _RandomQuizScreenState();
}

class _RandomQuizScreenState extends ConsumerState<RandomQuizScreen> {
  static const _counts = [10, 20];

  List<Question> _all = const [];
  String _subject = 'すべて';
  int? _count = _counts.first; // null = 全問
  Object? _loadError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final repository = ref.read(questionRepositoryProvider);
      final retryIds = widget.questionIds;
      if (retryIds != null && retryIds.isNotEmpty) {
        final retry = await repository.fetchQuestionsByIds(retryIds);
        if (!mounted) return;
        setState(() => _loading = false);
        await openQuiz(context, ref, title: '間違えた問題の解き直し', questions: retry);
        if (mounted && context.canPop()) context.pop();
        return;
      }
      final questions = await repository.getAllQuestions();
      if (!mounted) return;
      setState(() {
        _all = questions;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  List<Question> get _pool => _all.where((q) => _subject == 'すべて' || q.subject == _subject).toList();

  Future<void> _start() async {
    final picked = _pool..shuffle(Random());
    final count = _count;
    await openQuiz(
      context,
      ref,
      title: 'ランダムクイズ',
      questions: count == null ? picked : picked.take(count).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.questionIds == null ? 'ランダムクイズ' : '間違えた問題の解き直し'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('問題を読み込めませんでした。'),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _load, child: const Text('再読み込み')),
                    ],
                  ),
                )
              : widget.questionIds != null
                  ? const Center(child: Text('解き直しが終わりました'))
                  : _setup(),
    );
  }

  Widget _setup() {
    final pool = _pool.length;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('全部の過去問からランダムに出題します。', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            const Text('科目', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'すべて', label: Text('すべて')),
                ButtonSegment(value: '科目A', label: Text('科目A')),
                ButtonSegment(value: '科目B', label: Text('科目B')),
              ],
              selected: {_subject},
              onSelectionChanged: (s) => setState(() => _subject = s.first),
            ),
            const SizedBox(height: 20),
            const Text('問題数', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            SegmentedButton<int?>(
              segments: [
                for (final c in _counts) ButtonSegment(value: c, label: Text('$c問')),
                const ButtonSegment(value: null, label: Text('全問')),
              ],
              selected: {_count},
              onSelectionChanged: (s) => setState(() => _count = s.first),
            ),
            const SizedBox(height: 16),
            Text('出題できる問題：$pool問', style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 32),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: pool == 0 ? null : _start,
              child: const Text('スタート', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
