import 'dart:convert';

import '../../../core/theme/course_colors.dart';
import '../../../models/course.dart';
import '../../../models/section_time.dart';
import '../../../models/semester.dart';
import '../../../services/course_time_service.dart';

/// 载荷协议版本，Android 侧 `WidgetPayloadParser` 按此判断兼容性。
const int widgetPayloadSchemaVersion = 1;

/// 构建推送给 Android 桌面小组件的 JSON 载荷。
///
/// 载荷只包含「整周原始数据」——学期起点、总周数、全部课程与节次时间。
/// 「今天是第几周、今天有哪些课」由原生侧按设备日期自行计算，因此 App 未运行
/// 时小组件仍能显示正确内容；反过来，App 内手动切换查看周不会影响小组件。
String buildWidgetPayload({
  required Semester? semester,
  required List<Course> courses,
  required List<SectionTime> sectionTimes,
}) {
  return jsonEncode({
    'schemaVersion': widgetPayloadSchemaVersion,
    'semester': semester == null
        ? null
        : {
            'name': semester.name,
            'firstWeekMonday': _isoDate(semester.firstWeekMonday),
            'totalWeeks': semester.totalWeeks,
          },
    'courses': courses.map((course) {
      final time = const CourseTimeService().resolve(
        course,
        sectionTimes: sectionTimes,
      );
      return {
        'name': course.name,
        'classroom': course.classroom,
        'weekday': course.weekday,
        'startSection': course.startSection,
        'endSection': course.endSection,
        'startTime': time?.startTime,
        'endTime': time?.endTime,
        'weeks': course.weeks,
        'colorHex': _hexColor(course.colorKey),
      };
    }).toList(),
    'sectionTimes': [
      for (final time in sectionTimes)
        {
          'section': time.section,
          'startTime': time.startTime,
          'endTime': time.endTime,
        },
    ],
  });
}

/// 纯日期字符串，避免时区在两端解析时产生偏差。
String _isoDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// 与课表 UI 同一取色规则下的 `#RRGGBB`，供原生侧 `Color.parseColor` 直接使用。
String _hexColor(int colorKey) {
  final rgb = courseColorFor(colorKey).toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
