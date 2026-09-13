import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/features/notifications/services/notification_planner.dart';
import 'package:ncpu_timetable/models/course.dart';
import 'package:ncpu_timetable/models/section_time.dart';
import 'package:ncpu_timetable/models/semester.dart';

void main() {
  const planner = NotificationPlanner();
  final semester = Semester(
    id: 's1',
    name: '测试学期',
    firstWeekMonday: DateTime(2026, 9, 7),
    totalWeeks: 2,
  );
  const sectionTimes = [
    SectionTime(section: 1, startTime: '08:20', endTime: '09:00'),
    SectionTime(section: 3, startTime: '10:25', endTime: '11:05'),
  ];

  test('按教学周、星期和作息生成未来提醒', () {
    final reminders = planner.build(
      semester: semester,
      courses: [
        _course(weeks: const [1, 2]),
      ],
      sectionTimes: sectionTimes,
      now: DateTime(2026, 9, 6, 12),
      minutesBefore: 15,
    );

    expect(reminders, hasLength(2));
    expect(reminders[0].courseStart, DateTime(2026, 9, 7, 8, 20));
    expect(reminders[0].scheduledAt, DateTime(2026, 9, 7, 8, 5));
    expect(reminders[1].courseStart, DateTime(2026, 9, 14, 8, 20));
    expect(reminders[0].title, '高等数学 即将上课');
    expect(reminders[0].body, '08:20 · A101');
    expect(reminders[0].payload, 'course:c1');
    expect(reminders[0].id, isNot(equals(reminders[1].id)));
  });

  test('课程明确时间优先，特定教学楼沿用提前作息', () {
    final explicit = _course(
      id: 'explicit',
      startSection: 3,
      startTime: '09:30',
      classroom: '明志楼 201',
    );
    final building = _course(
      id: 'building',
      startSection: 3,
      classroom: '明志楼 201',
    );

    final reminders = planner.build(
      semester: semester,
      courses: [explicit, building],
      sectionTimes: sectionTimes,
      now: DateTime(2026, 9, 6),
      minutesBefore: 5,
    );

    expect(
      reminders.map(
        (value) => value.courseStart.hour * 60 + value.courseStart.minute,
      ),
      containsAll([9 * 60 + 30, 10 * 60 + 15]),
    );
  });

  test('过期、越界教学周和无法解析时间的课程不排程', () {
    final reminders = planner.build(
      semester: semester,
      courses: [
        _course(id: 'past', weeks: const [1]),
        _course(id: 'outside', weeks: const [3]),
        _course(id: 'invalid', weeks: const [2], startSection: 99),
      ],
      sectionTimes: sectionTimes,
      now: DateTime(2026, 9, 8),
      minutesBefore: 15,
    );

    expect(reminders, isEmpty);
  });

  test('结果按时间排序并限制系统闹钟数量', () {
    final reminders = planner.build(
      semester: semester,
      courses: [
        _course(id: 'late', startTime: '09:30'),
        _course(id: 'early', startTime: '08:30'),
      ],
      sectionTimes: sectionTimes,
      now: DateTime(2026, 9, 6),
      minutesBefore: 15,
      maxNotifications: 1,
    );

    expect(reminders, hasLength(1));
    expect(reminders.single.course.id, 'early');
  });

  test('校园挂钟基准取 UTC+8 的挂钟分量，不随设备时区漂移', () {
    final expected = DateTime.now().toUtc().add(campusUtcOffset);
    final actual = campusWallClockNow();
    // 两个 DateTime 的“时刻”基准不同（一个是设备本地、一个是 UTC），
    // 只能比较挂钟分量；允许分钟边界上的一分钟误差。
    int minutesOfDay(DateTime value) =>
        value.day * 24 * 60 + value.hour * 60 + value.minute;
    expect(
      (minutesOfDay(actual) - minutesOfDay(expected)).abs(),
      lessThanOrEqualTo(1),
    );
  });

  test('排程前过滤掉触发点已过的提醒', () {
    final reminders = planner.build(
      semester: semester,
      courses: [
        _course(weeks: const [1, 2]),
      ],
      sectionTimes: sectionTimes,
      now: DateTime(2026, 9, 6, 12),
      minutesBefore: 15,
    );
    expect(reminders, hasLength(2));

    expect(
      futureReminders(reminders, DateTime(2026, 9, 7, 8, 4)),
      hasLength(2),
      reason: '两条都还没到触发点',
    );
    expect(
      futureReminders(reminders, DateTime(2026, 9, 7, 8, 5)),
      hasLength(1),
      reason: '第一条恰好到点，不应再排',
    );
    expect(
      futureReminders(reminders, DateTime(2026, 9, 14, 9)),
      isEmpty,
      reason: '全部过期时返回空，而不是把已过期的交给插件',
    );
  });
}

Course _course({
  String id = 'c1',
  List<int> weeks = const [1],
  int startSection = 1,
  String? startTime,
  String classroom = 'A101',
}) => Course(
  id: id,
  name: '高等数学',
  classroom: classroom,
  weekday: 1,
  startSection: startSection,
  endSection: startSection,
  startTime: startTime,
  weeks: weeks,
  semesterId: 's1',
  colorKey: 1,
);
