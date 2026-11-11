import 'package:flutter/material.dart';

class RandomQuizScreen extends StatefulWidget {
  const RandomQuizScreen({super.key});

  @override
  State<RandomQuizScreen> createState() => _RandomQuizScreenState();
}

class _RandomQuizScreenState extends State<RandomQuizScreen> {
  // 選択状態を管理する変数
  int _selectedSubjectIndex = 0; // 0: 科目A, 1: 科目B
  String _selectedQuestionSet = 'すべて';
  String _selectedCategory = 'すべて';
  String _selectedCount = '10問';

  // 科目ごとの問題セット
  List<String> get _currentQuestionSets {
    if (_selectedSubjectIndex == 0) {
      return [
        'すべて',
        '令和8年度 公開問題',
        '令和7年度 公開問題',
        '令和6年度 公開問題',
        '令和5年度 公開問題',
        '平成31年度 春期 午前',
        '平成30年度 秋期 午前',
      ];
    } else {
      return [
        'すべて',
        '令和8年度 公開問題',
        '令和7年度 公開問題',
      ];
    }
  }

  // 科目ごとの分野（科目Bは空にして「まだ問題がありません」を表示する）
  List<String> get _currentCategories {
    if (_selectedSubjectIndex == 0) {
      return [
        'すべて',
        'データベース',
        'ネットワーク',
        'セキュリティ',
        '基礎理論',
        'アルゴリズム',
        'マネジメント',
      ];
    } else {
      return []; // 科目Bは分野なし
    }
  }

  final List<String> _counts = ['10問', '20問', '全問'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // 背景色をスッキリ見やすく調整
      appBar: AppBar(
        title: const Text('ランダムクイズ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ① 科目切り替えタブ
            const Text(
              '科目',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Container(
              width: 320,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedSubjectIndex = 0;
                        _selectedQuestionSet = 'すべて';
                        _selectedCategory = 'すべて';
                      }),
                      child: Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: _selectedSubjectIndex == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: _selectedSubjectIndex == 0
                              ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                              : [],
                        ),
                        child: Text(
                          '科目A',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _selectedSubjectIndex == 0 ? Colors.blue : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedSubjectIndex = 1;
                        _selectedQuestionSet = 'すべて';
                        _selectedCategory = 'すべて';
                      }),
                      child: Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: _selectedSubjectIndex == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: _selectedSubjectIndex == 1
                              ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                              : [],
                        ),
                        child: Text(
                          '科目B',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _selectedSubjectIndex == 1 ? Colors.blue : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ② 問題セット選択
            const Text(
              '問題セット',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _currentQuestionSets.map((set) {
                final isSelected = _selectedQuestionSet == set;
                return ChoiceChip(
                  label: Text(set),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedQuestionSet = set);
                  },
                  selectedColor: Colors.blue[50],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue[700] : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ③ 分野選択
            const Text(
              '分野',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            _currentCategories.isEmpty
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                'まだ問題がありません',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            )
                : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _currentCategories.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = category);
                  },
                  selectedColor: Colors.blue[50],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue[700] : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ④ 問題数選択
            const Text(
              '問題数',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              children: _counts.map((count) {
                final isSelected = _selectedCount == count;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected ? Colors.blue[50] : Colors.white,
                        side: BorderSide(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => setState(() => _selectedCount = count),
                      child: Text(
                        count,
                        style: TextStyle(
                          color: isSelected ? Colors.blue[700] : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            // ⑤ スタートボタン（科目Bで分野がない場合などは無効にするなどの調整も可能）
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  // クイズ開始処理
                },
                child: const Text(
                  'スタート',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}