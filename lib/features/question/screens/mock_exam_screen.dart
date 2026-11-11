import 'package:flutter/material.dart';

class MockExamScreen extends StatefulWidget {
  const MockExamScreen({super.key});

  @override
  State<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends State<MockExamScreen> {
  // 選択状態を管理する変数 (0: 科目A, 1: 科目B)
  int _selectedSubjectIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isSubjectA = _selectedSubjectIndex == 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('模擬試験'),
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
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSubjectIndex = 0),
                      child: Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isSubjectA ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: isSubjectA
                              ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                              : [],
                        ),
                        child: Text(
                          '科目A',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSubjectA ? Colors.blue : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSubjectIndex = 1),
                      child: Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: !isSubjectA ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: !isSubjectA
                              ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                              : [],
                        ),
                        child: Text(
                          '科目B',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: !isSubjectA ? Colors.blue : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ② 試験情報カード群
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  // 問題数
                  _buildInfoTile(
                    icon: Icons.list_alt,
                    title: '問題数',
                    subtitle: isSubjectA ? '本番は60問・90分' : '本番は20問・100分',
                    trailing: isSubjectA ? '10問' : '0問',
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  // 制限時間
                  _buildInfoTile(
                    icon: Icons.timer_outlined,
                    title: '制限時間',
                    subtitle: '',
                    trailing: isSubjectA ? '15分' : '0分',
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  // 合格の目安
                  _buildInfoTile(
                    icon: Icons.flag_outlined,
                    title: '合格の目安',
                    subtitle: '',
                    trailing: '60%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 科目Bが選択されている場合の「準備中」メッセージ
            if (!isSubjectA)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    '科目Bの模試は準備中です',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // 注意事項のテキスト
            const Center(
              child: Text(
                '答えは最後にまとめて表示されます',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 32),

            // ③ 開始するボタン
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSubjectA ? Colors.blue : Colors.grey[300],
                  foregroundColor: isSubjectA ? Colors.white : Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: isSubjectA
                    ? () {
                  // 科目Aの模試開始処理
                }
                    : null, // 科目Bが準備中の場合はボタンを無効化
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.play_arrow, size: 20),
                    SizedBox(width: 4),
                    Text(
                      '開始する',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 情報カード内の各行を作るヘルパーウィジェット
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[600], size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}