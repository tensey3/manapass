import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/question.dart';
import '../../../data/repositories/question_repository.dart';

// 該当年度・科目の問題リストを取得するProvider
final questionsProvider = FutureProvider.family<List<Question>, ({int year, String subject})>((ref, arg) async {
  final repository = ref.read(questionRepositoryProvider);
  return await repository.getQuestionsByYearAndSubject(arg.year, arg.subject);
});

class QuestionAnswerScreen extends ConsumerStatefulWidget {
  final int year;
  final String subject;

  const QuestionAnswerScreen({
    super.key,
    required this.year,
    required this.subject,
  });

  @override
  ConsumerState<QuestionAnswerScreen> createState() => _QuestionAnswerScreenState();
}

class _QuestionAnswerScreenState extends ConsumerState<QuestionAnswerScreen> {
  int currentIndex = 0;
  int? selectedOptionIndex; // ユーザーが選択した選択肢のインデックス
  bool isAnswered = false;    // 解答ボタンが押されて答え合わせが終わったか

  /// 解答を記録する（進捗画面・復習画面がこの記録を使う）。
  /// 記録できなくても答え合わせは続けられるように、失敗はお知らせだけ出す。
  Future<void> _recordAnswer(Question question, int selectedIndex) async {
    try {
      await ref.read(questionRepositoryProvider).recordAnswer(question, selectedIndex);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('解答を記録できませんでした（進捗には反映されません）')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // データベースから問題リストを非同期で取得（widget.year と widget.subject を使用）
    final queryArg = (year: widget.year, subject: widget.subject);
    final questionsAsync = ref.watch(questionsProvider(queryArg));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${widget.year}年度 - ${widget.subject}',
          style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラーが発生しました: $error', style: const TextStyle(color: Colors.red)),
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(
              child: Text(
                'この条件に一致する問題がまだ登録されていません。',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final currentQuestion = questions[currentIndex];
          final progress = (currentIndex + 1) / questions.length;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 進捗バー ＆ 問題番号
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${currentQuestion.category} ・ 問${currentIndex + 1}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${currentIndex + 1} / ${questions.length}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 24),

                // 問題文 (questionText)
                Text(
                  currentQuestion.questionText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.5, color: Colors.black87),
                ),
                const SizedBox(height: 24),

                // 選択肢一覧 (options)
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQuestion.options.length,
                    itemBuilder: (context, index) {
                      final optionText = currentQuestion.options[index];
                      final isSelected = selectedOptionIndex == index;

                      // 選択肢のラベル（ア、イ、ウ、エ...）
                      const labels = ['ア', 'イ', 'ウ', 'エ', 'オ'];
                      final labelPrefix = index < labels.length ? '${labels[index]}. ' : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[50] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: RadioListTile<int>(
                          title: Text(
                            '$labelPrefix$optionText',
                            style: const TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                          value: index,
                          groupValue: selectedOptionIndex,
                          onChanged: isAnswered
                              ? null // 解答済みの場合は変更不可
                              : (value) {
                            setState(() {
                              selectedOptionIndex = value;
                            });
                          },
                          activeColor: Colors.blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ),

                // 解説表示（解答後に出す場合）
                if (isAnswered) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selectedOptionIndex == currentQuestion.correctIndex ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedOptionIndex == currentQuestion.correctIndex ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedOptionIndex == currentQuestion.correctIndex ? '正解！' : '不正解...',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selectedOptionIndex == currentQuestion.correctIndex ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentQuestion.explanation,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 解答する / 次へ ボタン
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: selectedOptionIndex == null
                        ? null
                        : () {
                      if (!isAnswered) {
                        // 1回目のタップ：解答合わせ
                        setState(() {
                          isAnswered = true;
                        });
                        _recordAnswer(questions[currentIndex], selectedOptionIndex!);
                      } else {
                        // 2回目のタップ：次の問題へ進む（あるいは終了）
                        if (currentIndex < questions.length - 1) {
                          setState(() {
                            currentIndex++;
                            selectedOptionIndex = null;
                            isAnswered = false;
                          });
                        } else {
                          // 最後の問題が終わったら閉じる
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    child: Text(
                      !isAnswered
                          ? '解答する'
                          : (currentIndex < questions.length - 1 ? '次の問題へ' : '終了する'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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