import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/question.dart';
import '../../../data/repositories/question_repository.dart';

class RandomQuizScreen extends ConsumerStatefulWidget {
  final List<String>? questionIds;

  const RandomQuizScreen({
    super.key,
    this.questionIds,
  });

  @override
  ConsumerState<RandomQuizScreen> createState() => _RandomQuizScreenState();
}

class _RandomQuizScreenState extends ConsumerState<RandomQuizScreen> {
  late Future<List<Question>> _questionsFuture;
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _isAnswered = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _loadQuestions();
  }

  Future<List<Question>> _loadQuestions() async {
    final repo = ref.read(questionRepositoryProvider);
    final ids = widget.questionIds;
    if (ids != null && ids.isNotEmpty) {
      return repo.fetchQuestionsByIds(ids);
    }
    return repo.getAllQuestions();
  }

  Future<void> _submitAnswer(Question question) async {
    final selected = _selectedIndex;
    if (selected == null || _isAnswered || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(questionRepositoryProvider).recordAnswer(question, selected);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('解答の記録に失敗しましたが、解説を確認できます')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isAnswered = true;
        });
      }
    }
  }

  void _nextQuestion(int totalCount) {
    if (_currentIndex < totalCount - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _isAnswered = false;
      });
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        title: const Text(
          '復習クイズ',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '問題の読み込みに失敗しました\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 0;
                          _selectedIndex = null;
                          _isAnswered = false;
                          _questionsFuture = _loadQuestions();
                        });
                      },
                      child: const Text('再読み込み'),
                    ),
                  ],
                ),
              ),
            );
          }

          final questions = snapshot.data ?? const <Question>[];
          if (questions.isEmpty) {
            return const Center(
              child: Text('解き直す問題がありません'),
            );
          }

          final safeIndex = _currentIndex.clamp(0, questions.length - 1);
          final question = questions[safeIndex];
          final choices = List<String>.from(question.choices);
          final isCorrect = _selectedIndex == question.answerIndex;
          final progress = (safeIndex + 1) / questions.length;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${question.category} ・ 問${safeIndex + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${safeIndex + 1} / ${questions.length}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: choices.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedIndex == index;
                      const labels = ['ア', 'イ', 'ウ', 'エ', 'オ'];
                      final prefix = index < labels.length ? '${labels[index]}. ' : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: RadioListTile<int>(
                          value: index,
                          groupValue: _selectedIndex,
                          onChanged: _isAnswered || _isSaving
                              ? null
                              : (val) => setState(() => _selectedIndex = val),
                          title: Text(
                            '$prefix${choices[index]}',
                            style: const TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_isAnswered) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCorrect ? '正解！（復習リストから解除されます）' : '不正解...',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                        if (question.explanation.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            question.explanation,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _selectedIndex == null || _isSaving
                        ? null
                        : () {
                      if (!_isAnswered) {
                        _submitAnswer(question);
                      } else {
                        _nextQuestion(questions.length);
                      }
                    },
                    child: Text(
                      !_isAnswered
                          ? (_isSaving ? '記録中...' : '解答する')
                          : (safeIndex < questions.length - 1 ? '次の問題へ' : '復習を終了する'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}