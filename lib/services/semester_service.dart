import '../models/semester.dart';

/// 《2026-2027学年教学周历》第一学期第 1 教学周周一，即 2026-08-31
/// （第 1 教学周为 2026-08-31 至 2026-09-06）。
///
/// 全新安装没有学期记录时以它为默认起点。不能用“安装当天所在周的周一”推断：
/// 那会让第 2 周及以后安装的设备全部少算一周，并使单双周、限定周次课程错位。
/// 进入新学期时需更新此常量，用户也可在“设置 → 学期设置”中自行修改。
final officialFirstWeekMonday = DateTime(2026, 8, 31);

class SemesterService {
  const SemesterService();

  int currentWeek(Semester semester, DateTime date) {
    final difference = _dateOnly(date)
        .difference(_dateOnly(semester.firstWeekMonday))
        .inDays;
    if (difference < 0) return 0;
    final week = difference ~/ 7 + 1;
    return week > semester.totalWeeks ? semester.totalWeeks : week;
  }

  DateTime weekMonday(Semester semester, int week) {
    final safeWeek = week.clamp(1, semester.totalWeeks);
    return _dateOnly(semester.firstWeekMonday)
        .add(Duration(days: (safeWeek - 1) * 7));
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
