import '../models/semester.dart';

/// 《2026-2027学年教学周历》第一学期第 1 教学周周一，即 2026-08-31
/// （第 1 教学周为 2026-08-31 至 2026-09-06）。
///
/// 全新安装没有学期记录时以它为默认起点。不能用“安装当天所在周的周一”推断：
/// 那会让第 2 周及以后安装的设备全部少算一周，并使单双周、限定周次课程错位。
/// 进入新学期时需更新此常量，用户也可在“设置 → 学期设置”中自行修改。
final officialFirstWeekMonday = DateTime(2026, 8, 31);

/// 默认教学周数。
///
/// 只用于全新安装时播种默认学期；每个学期可在“设置 → 学期设置”里单独修改，
/// 因此读取时一律用 `Semester.totalWeeks`，不要用这个常量。
const defaultTotalWeeks = 20;

/// 某个日期相对学期区间的位置。
///
/// [SemesterService.currentWeek] 会把超出学期的周次封顶到 `totalWeeks`，
/// 因此“正在最后一周”和“学期早已结束”无法区分。需要判断学期日期是否
/// 已经过期时用 [SemesterService.termStatus]。
enum TermStatus {
  /// 早于开学第一周周一。
  before,

  /// 落在配置的教学周范围内。
  within,

  /// 已超出 `totalWeeks` 周。
  after,
}

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

  /// 判断 [date] 位于学期之前、之中还是之后。
  TermStatus termStatus(Semester semester, DateTime date) {
    final today = _dateOnly(date);
    final start = _dateOnly(semester.firstWeekMonday);
    if (today.isBefore(start)) return TermStatus.before;
    final endExclusive = start.add(Duration(days: semester.totalWeeks * 7));
    return today.isBefore(endExclusive) ? TermStatus.within : TermStatus.after;
  }

  /// 第 [week] 周星期 [weekday]（1=周一）的日期。
  ///
  /// 与 [weekMonday] 不同，这里**不**把 [week] 夹到学期范围内：周次条与
  /// 日程列表需要如实显示用户翻到的那一周。
  DateTime dateFor(Semester semester, int week, int weekday) =>
      _dateOnly(semester.firstWeekMonday)
          .add(Duration(days: (week - 1) * 7 + weekday - 1));

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
