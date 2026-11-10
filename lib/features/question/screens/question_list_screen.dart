import 'package:flutter/material.dart';

class QuestionListScreen extends StatefulWidget {
  const QuestionListScreen({super.key});

  @override
  State<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ① 画面タイトル
            const Text(
              '問題',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // ②③④ 操作ボタン群
            Row(
              children: [
                _buildActionButton(
                  icon: Icons.close,
                  label: 'ランダムクイズ',
                  onTap: () {},
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.timer,
                  label: '模擬試験',
                  onTap: () {},
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.camera_alt,
                  label: '写真から追加',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ⑤⑥⑦ 年度別見出し ＆ 科目A / 科目Bタブ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '年度別',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  width: 250,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey[600],
                    tabs: const [
                      Tab(text: '科目A'),
                      Tab(text: '科目B'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ⑧⑨ 年度別問題カード一覧
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 科目Aのリストデータ
                  _buildQuestionListView([
                    {'title': '令和8年度 公開問題', 'info': '科目A・20問', 'solved': 0, 'total': 20},
                    {'title': '令和7年度 公開問題', 'info': '科目A・20問', 'solved': 4, 'total': 20},
                    {'title': '令和6年度 公開問題', 'info': '科目A・20問', 'solved': 20, 'total': 20},
                    {'title': '令和5年度 公開問題', 'info': '科目A・20問', 'solved': 12, 'total': 20},
                  ]),
                  // 科目Bのリストデータ
                  _buildQuestionListView([
                    {'title': '令和8年度 公開問題', 'info': '科目B・5問', 'solved': 0, 'total': 5},
                    {'title': '令和7年度 公開問題', 'info': '科目B・5問', 'solved': 2, 'total': 5},
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 操作ボタンのウィジェット
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 問題一覧のリストビューを構築するウィジェット（記号エラー防止版）
  Widget _buildQuestionListView(List datalist) {
    return ListView.builder(
      itemCount: datalist.length,
      itemBuilder: (context, index) {
        final data = datalist[index];
        final solved = data['solved'] as int;
        final total = data['total'] as int;
        final progress = solved / total;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['info'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$solved/$total',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              solved == total ? Colors.green : Colors.blue,
                            ),
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
            ],
          ),
        );
      },
    );
  }
}