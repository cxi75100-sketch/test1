import '../../../models/course.dart';
import '../../../models/section_time.dart';
import '../../../models/semester.dart';
import '../../../services/course_time_service.dart';

const maxScheduledCourseNotifications = 480;

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
