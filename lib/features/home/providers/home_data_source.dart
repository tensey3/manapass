/// ホーム画面専用のデータ取得インターフェース。
/// 共有の data/repositories には依存しない（担当範囲を重ねないため）。
/// 後で共通リポジトリに置き換える場合は、この abstract class を実装し直すだけでよい。
class HomeData {
  final String? examName;
  final DateTime? examDate;
  final int todayAnswered;
  final int dailyGoal;

  const HomeData({
    this.examName,
    this.examDate,
    required this.todayAnswered,
    required this.dailyGoal,
  });

  /// 試験日までの日数（日付単位。当日は0）。未設定なら null。
  int? get daysLeft {
    final d = examDate;
    if (d == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(d.year, d.month, d.day).difference(today).inDays;
  }

  int get remaining => (dailyGoal - todayAnswered).clamp(0, dailyGoal);
  double get progress => dailyGoal == 0 ? 0 : (todayAnswered / dailyGoal).clamp(0.0, 1.0);
}

abstract class HomeDataSource {
  Future<HomeData> load();
}

/// 画面確認用のダミーデータ（スクリーンショットと同じ値）。
class DemoHomeDataSource implements HomeDataSource {
  const DemoHomeDataSource();
  @override
  Future<HomeData> load() async => HomeData(
        examName: '基本情報技術者試験',
        examDate: DateTime.now().add(const Duration(days: 42)),
        todayAnswered: 5,
        dailyGoal: 10,
      );
}
