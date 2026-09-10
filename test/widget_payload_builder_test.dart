import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/features/widget/services/widget_payload_builder.dart';
import 'package:ncpu_timetable/models/course.dart';
import 'package:ncpu_timetable/models/section_time.dart';
import 'package:ncpu_timetable/models/semester.dart';
import 'package:ncpu_timetable/services/course_time_service.dart';

void main() {
  final semester = Semester(
    id: 'semester-1',
    name: '2026 秋',
    firstWeekMonday: DateTime(2026, 9, 7),
    totalWeeks: 20,
  );

  Map<String, dynamic> decode(String payload) =>
      jsonDecode(payload) as Map<String, dynamic>;

  test('载荷包含学期起点、总周数与协议版本', () {
    final payload = decode(
      buildWidgetPayload(
        semester: semester,
        courses: const [],
        sectionTimes: const [],
      ),
    );

    expect(payload['schemaVersion'], widgetPayloadSchemaVersion);
    final encodedSemester = payload['semester'] as Map<String, dynamic>;
    expect(encodedSemester['name'], '2026 秋');
    expect(encodedSemester['firstWeekMonday'], '2026-09-07');
    expect(encodedSemester['totalWeeks'], 20);
    expect(payload['courses'], isEmpty);
  });

  test('没有学期时 semester 为 null，课程仍为空列表', () {
    final payload = decode(
      buildWidgetPayload(
        semester: null,
        courses: const [],
        sectionTimes: const [],
      ),
    );

    expect(payload['semester'], isNull);
    expect(payload['courses'], isEmpty);
  });

  test('课程序列化星期、节次、生效周次与颜色', () {
    final payload = decode(
      buildWidgetPayload(
        semester: semester,
        courses: const [
          Course(
            id: 'course-1',
            name: '高等数学',
            classroom: 'A101',
            weekday: 1,
            startSection: 1,
            endSection: 2,
            weeks: [1, 2, 3, 5],
            semesterId: 'semester-1',
            colorKey: 0,
          ),
        ],
        sectionTimes: const [],
      ),
    );

    final course = (payload['courses'] as List).single as Map<String, dynamic>;
    expect(course['name'], '高等数学');
    expect(course['classroom'], 'A101');
    expect(course['weekday'], 1);
    expect(course['startSection'], 1);
    expect(course['endSection'], 2);
    expect(course['weeks'], [1, 2, 3, 5]);
    // 载荷直接携带按教室解析后的时间，确保原生小组件与 App 一致。
    expect(course['startTime'], isNull);
    expect(course['endTime'], isNull);
    expect(course['colorHex'], matches(RegExp(r'^#[0-9A-F]{6}$')));
  });

  test('课程颜色与课表 UI 使用同一取色规则（含 colorKey 取绝对值）', () {
    String colorHexOf(int colorKey) {
      final payload = decode(
        buildWidgetPayload(
          semester: semester,
          courses: [
            Course(
              id: 'course-$colorKey',
              name: '课程',
              weekday: 1,
              startSection: 1,
              endSection: 1,
              weeks: const [1],
              semesterId: 'semester-1',
              colorKey: colorKey,
            ),
          ],
          sectionTimes: const [],
        ),
      );
      return ((payload['courses'] as List).single
              as Map<String, dynamic>)['colorHex']
          as String;
    }

    expect(colorHexOf(0), '#5B8FF9');
    expect(colorHexOf(6), '#9661BC');
    expect(colorHexOf(-6), '#9661BC');
  });

  test('节次时间按节次序号序列化', () {
    final payload = decode(
      buildWidgetPayload(
        semester: semester,
        courses: const [],
        sectionTimes: const [
          SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
          SectionTime(section: 2, startTime: '08:55', endTime: '09:40'),
        ],
      ),
    );

    final times = (payload['sectionTimes'] as List)
        .cast<Map<String, dynamic>>();
    expect(times, hasLength(2));
    expect(times.first['section'], 1);
    expect(times.first['startTime'], '08:00');
    expect(times.first['endTime'], '08:45');
  });

  test('小组件课程时间按教学楼规则解析', () {
    final payload = decode(
      buildWidgetPayload(
        semester: semester,
        courses: const [
          Course(
            id: 'course-1',
            name: '课程',
            classroom: '明志楼404',
            weekday: 1,
            startSection: 3,
            endSection: 4,
            weeks: [1],
            semesterId: 'semester-1',
            colorKey: 0,
          ),
        ],
        sectionTimes: officialSectionTimes,
      ),
    );

    final course = (payload['courses'] as List).single as Map<String, dynamic>;
    expect(course['startTime'], '10:15');
    expect(course['endTime'], '11:45');
  });
}
