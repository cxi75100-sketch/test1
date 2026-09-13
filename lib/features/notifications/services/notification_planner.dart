import '../../../models/course.dart';
import '../../../models/section_time.dart';
import '../../../models/semester.dart';
import '../../../services/course_time_service.dart';

const maxScheduledCourseNotifications = 480;

/// 校园所在地的固定时区偏移（Asia/Shanghai 全年 UTC+8，无夏令时）。
const campusUtcOffset = Duration(hours: 8);

/// 校园挂钟时间，用来和课表里的挂钟时间（节次作息、学期日期）比较。
///
/// 课表里的时间是校园挂钟分量，判断“是否已过去”必须用同一个挂钟基准。
/// 直接拿 `DateTime.now()`（设备本地时间）比较会在设备时区不是 UTC+8 时
/// 判错：设备时区落后于校园时，当天已经上过的课会被当成未来，交给通知
/// 插件时被 `scheduledDate` 校验拒绝；设备时区超前时，未来几小时的课
/// 反而会被丢掉。
///
/// 返回值刻意构造成“设备本地时刻的挂钟分量 == 校园挂钟”，这样它与课表
/// 时间的比较等价于纯挂钟比较，不依赖设备时区。
DateTime campusWallClockNow() {
  final campus = DateTime.now().toUtc().add(campusUtcOffset);
  return DateTime(
    campus.year,
    campus.month,
    campus.day,
    campus.hour,
    campus.minute,
    campus.second,
    campus.millisecond,
    campus.microsecond,
  );
}

/// 丢掉触发点已经过去的提醒。
///
/// 规划到真正排程之间可能跨过触发点，而通知插件对过去时间会抛异常；
/// 排程实现是“先清空、再逐条排程”，单条过期就会把已有提醒全部抹掉，
/// 因此排程前必须再挡一次。
List<CourseReminder> futureReminders(
  List<CourseReminder> reminders,
  DateTime now,
) => [
  for (final reminder in reminders)
    if (reminder.scheduledAt.isAfter(now)) reminder,
];

class CourseReminder {
  const CourseReminder({
    required this.id,
    required this.course,
    required this.courseStart,
    required this.scheduledAt,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final Course course;
  final DateTime courseStart;
  final DateTime scheduledAt;
  final String title;
  final String body;
  final String payload;
}

class NotificationPlanner {
  const NotificationPlanner({
    this.courseTimeService = const CourseTimeService(),
  });

  final CourseTimeService courseTimeService;

  List<CourseReminder> build({
    required Semester semester,
    required List<Course> courses,
    required List<SectionTime> sectionTimes,
    required DateTime now,
    required int minutesBefore,
    int maxNotifications = maxScheduledCourseNotifications,
  }) {
    if (maxNotifications <= 0) return const [];
    final values = <CourseReminder>[];
    final usedIds = <int>{};

    for (final course in courses) {
      if (course.semesterId != semester.id ||
          course.weekday < DateTime.monday ||
          course.weekday > DateTime.sunday) {
        continue;
      }
      final range = courseTimeService.resolve(
        course,
        sectionTimes: sectionTimes,
      );
      final time = range == null ? null : _parseTime(range.startTime);
      if (time == null) continue;

      for (final week in course.weeks.toSet()) {
        if (week < 1 || week > semester.totalWeeks) continue;
        final date = _dateOnly(semester.firstWeekMonday)
            .add(Duration(days: (week - 1) * 7 + course.weekday - 1));
        final courseStart = DateTime(
          date.year,
          date.month,
          date.day,
          time.$1,
          time.$2,
        );
        final scheduledAt = courseStart.subtract(
          Duration(minutes: minutesBefore),
        );
        if (!scheduledAt.isAfter(now)) continue;

        final key = '${course.id}|${courseStart.millisecondsSinceEpoch}';
        var id = _stablePositiveHash(key);
        while (!usedIds.add(id)) {
          id = id == 0x7fffffff ? 1 : id + 1;
        }
        final location = course.classroom.trim();
        values.add(
          CourseReminder(
            id: id,
            course: course,
            courseStart: courseStart,
            scheduledAt: scheduledAt,
            title: '${course.name} 即将上课',
            body: location.isEmpty
                ? range!.startTime
                : '${range!.startTime} · $location',
            payload: 'course:${course.id}',
          ),
        );
      }
    }

    values.sort((a, b) {
      final timeOrder = a.scheduledAt.compareTo(b.scheduledAt);
      return timeOrder != 0 ? timeOrder : a.id.compareTo(b.id);
    });
    return values.length <= maxNotifications
        ? values
        : values.sublist(0, maxNotifications);
  }

  (int, int)? _parseTime(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return (hour, minute);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  int _stablePositiveHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}
