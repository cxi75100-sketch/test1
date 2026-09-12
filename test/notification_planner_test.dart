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
