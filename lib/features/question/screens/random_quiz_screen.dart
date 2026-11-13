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
  String _selectedTopic = 'すべて';
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
    Future.microtask(
      widget.questionIds == null
          ? _loadAvailableQuestions
          : _loadRetryQuestions,
    );
  }

  Future<void> _loadAvailableQuestions() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final questions = await ref
          .read(questionRepositoryProvider)
          .fetchQuestions();
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

  Future<void> _loadRetryQuestions() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final questions = await ref
          .read(questionRepositoryProvider)
          .fetchQuestionsByIds(widget.questionIds!);
      if (!mounted) return;
      setState(() {
        _quizQuestions = questions;
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
                  _selectedTopic == 'すべて' || question.topic == _selectedTopic,
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
      await ref.read(questionRepositoryProvider).recordAnswer(question, answer);
      if (!mounted) return;
      setState(() {
        _savingAnswer = false;
        _answered = true;
        if (answer == question.answerIndex) _correctCount++;
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
              'Firestoreから問題を読み込めませんでした。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Firestoreの有効化、ログイン状態、セキュリティルールを確認してください。\n$_loadError',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: widget.questionIds == null
                  ? _loadAvailableQuestions
                  : _loadRetryQuestions,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSetup() {
    final categories = _availableQuestions.map((q) => q.topic).toSet().toList()
      ..sort();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Firestoreに登録された問題を出題します。',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          initialValue: _selectedTopic,
          decoration: const InputDecoration(
            labelText: '分野',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: 'すべて', child: Text('すべて')),
            for (final category in categories)
              DropdownMenuItem(value: category, child: Text(category)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _selectedTopic = value);
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int?>(
          initialValue: _selectedCount,
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
            '問題がまだありません。Firebase ConsoleのFirestore Databaseで '
            'questions コレクションに問題を追加してください。',
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
          '対象の問題がありません。分野を変えるか、Firestoreに問題を追加してください。',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildQuestion(Question question) {
    final isCorrect = _selectedAnswer == question.answerIndex;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '${_currentIndex + 1} / ${_quizQuestions!.length}問  ・  '
          '${question.category} / ${question.topic}',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Text(
          question.text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        for (var index = 0; index < question.choices.length; index++)
          Card(
            color: _answered && index == question.answerIndex
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
                    Expanded(child: Text(question.choices[index])),
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
