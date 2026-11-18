import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/question.dart';
import '../../../data/repositories/question_repository.dart';

class RandomQuizScreen extends ConsumerStatefulWidget {
  const RandomQuizScreen({super.key, this.questionIds});

  final List<String>? questionIds;

  @override
  ConsumerState<RandomQuizScreen> createState() => _RandomQuizScreenState();
}

class _RandomQuizScreenState extends ConsumerState<RandomQuizScreen> {
  static const _questionCounts = [10, 20];

  List<Question> _availableQuestions = const [];
  List<Question>? _quizQuestions;
  String _selectedSubject = 'すべて'; // 旧 topic から subject 軸に変更
  int? _selectedCount = _questionCounts.first;
  int _currentIndex = 0;
  int _correctCount = 0;
  int? _selectedAnswer;
  Object? _loadError;
  Object? _answerError;
  bool _loading = true;
  bool _savingAnswer = false;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadAvailableQuestions);
  }

  Future<void> _loadAvailableQuestions() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final repository = ref.read(questionRepositoryProvider);

      // 復習画面の「解き直す」から来たときは、その問題だけをすぐ出題する
      final retryIds = widget.questionIds;
      if (retryIds != null && retryIds.isNotEmpty) {
        final retry = await repository.fetchQuestionsByIds(retryIds);
        if (!mounted) return;
        setState(() {
          _availableQuestions = retry;
          _quizQuestions = retry;
          _loading = false;
        });
        return;
      }

      // リポジトリから全問題を取得
      final questions = await repository.getAllQuestions();

      if (!mounted) return;
      setState(() {
        _availableQuestions = questions;
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

  void _startQuiz() {
    final selected =
    _availableQuestions
        .where(
          (question) =>
      _selectedSubject == 'すべて' || question.subject == _selectedSubject,
    )
        .toList()
      ..shuffle(Random());
    final count = _selectedCount;
    setState(() {
      _quizQuestions = count == null ? selected : selected.take(count).toList();
      _currentIndex = 0;
      _correctCount = 0;
      _selectedAnswer = null;
      _answered = false;
    });
  }

  Future<void> _submitAnswer() async {
    final questions = _quizQuestions!;
    final question = questions[_currentIndex];
    final answer = _selectedAnswer;
    if (answer == null || _savingAnswer) return;

    setState(() {
      _savingAnswer = true;
      _answerError = null;
    });
    try {
      // 解答を記録する（進捗画面・復習画面がこの記録を使う）
      await ref.read(questionRepositoryProvider).recordAnswer(question, answer);

      if (!mounted) return;
      setState(() {
        _savingAnswer = false;
        _answered = true;
        // correctIndex と比較
        if (answer == question.correctIndex) _correctCount++;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _savingAnswer = false;
        _answerError = error;
      });
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex++;
      _selectedAnswer = null;
      _answered = false;
      _answerError = null;
    });
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
          ? _buildLoadError()
          : _quizQuestions == null
          ? _buildQuizSetup()
          : _quizQuestions!.isEmpty
          ? _buildEmptyQuiz()
          : _currentIndex >= _quizQuestions!.length
          ? _buildResult()
          : _buildQuestion(_quizQuestions![_currentIndex]),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '問題を読み込めませんでした。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'エラー内容:\n$_loadError',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadAvailableQuestions,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSetup() {
    final subjects = _availableQuestions.map((q) => q.subject).toSet().toList()
      ..sort();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          '登録された問題からランダムに出題します。',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          value: _selectedSubject,
          decoration: const InputDecoration(
            labelText: '科目',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: 'すべて', child: Text('すべて')),
            for (final subject in subjects)
              DropdownMenuItem(value: subject, child: Text(subject)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _selectedSubject = value);
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int?>(
          value: _selectedCount,
          decoration: const InputDecoration(
            labelText: '問題数',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final count in _questionCounts)
              DropdownMenuItem(value: count, child: Text('$count問まで')),
            const DropdownMenuItem(value: null, child: Text('全問')),
          ],
          onChanged: (value) => setState(() => _selectedCount = value),
        ),
        const SizedBox(height: 12),
        Text('登録問題数：${_availableQuestions.length}問'),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: _availableQuestions.isEmpty ? null : _startQuiz,
          child: const Text('スタート'),
        ),
        if (_availableQuestions.isEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            '問題がまだありません。データベースに問題を追加してください。',
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyQuiz() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '対象の問題がありません。条件を変えてお試しください。',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildQuestion(Question question) {
    // answerIndex -> correctIndex に変更
    final isCorrect = _selectedAnswer == question.correctIndex;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '${_currentIndex + 1} / ${_quizQuestions!.length}問  ・  '
              '${question.category} / ${question.subject}',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        // text -> questionText に変更
        Text(
          question.questionText,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        // choices -> options に変更
        for (var index = 0; index < question.options.length; index++)
          Card(
            color: _answered && index == question.correctIndex
                ? Colors.green[50]
                : _answered && index == _selectedAnswer
                ? Colors.red[50]
                : Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _answered || _savingAnswer
                  ? null
                  : () => setState(() => _selectedAnswer = index),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _selectedAnswer == index
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: _selectedAnswer == index
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black54,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(question.options[index])),
                  ],
                ),
              ),
            ),
          ),
        if (_answered) ...[
          const SizedBox(height: 12),
          Text(
            isCorrect ? '正解です' : '不正解です',
            style: TextStyle(
              color: isCorrect ? Colors.green[700] : Colors.red[700],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('解説：${question.explanation}'),
        ],
        if (_answerError != null) ...[
          const SizedBox(height: 12),
          Text(
            '解答記録を保存できませんでした。$_answerError',
            style: const TextStyle(color: Colors.red),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _savingAnswer
              ? null
              : _answered
              ? _nextQuestion
              : _selectedAnswer == null
              ? null
              : _submitAnswer,
          child: _savingAnswer
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(_answered ? '次の問題' : '回答する'),
        ),
      ],
    );
  }

  Widget _buildResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'お疲れさまでした',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('正解 $_correctCount / ${_quizQuestions!.length} 問'),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('戻る'),
            ),
          ],
        ),
      ),
    );
  }
}