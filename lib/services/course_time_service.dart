import '../models/course.dart';
import '../models/section_time.dart';

/// 《2026-2027学年教学周历》公布的通用作息。
///
/// 第 3、4 节在明志楼、明德楼、至善楼有单独时间，由
/// [CourseTimeService.resolve] 根据课程教室覆盖。
const officialSectionTimes = <SectionTime>[
  SectionTime(section: 1, startTime: '08:20', endTime: '09:00'),
  SectionTime(section: 2, startTime: '09:10', endTime: '09:50'),
  SectionTime(section: 3, startTime: '10:25', endTime: '11:05'),
  SectionTime(section: 4, startTime: '11:15', endTime: '11:55'),
  SectionTime(section: 5, startTime: '14:00', endTime: '14:40'),
  SectionTime(section: 6, startTime: '14:50', endTime: '15:30'),
  SectionTime(section: 7, startTime: '15:55', endTime: '16:35'),
  SectionTime(section: 8, startTime: '16:45', endTime: '17:25'),
  SectionTime(section: 9, startTime: '19:00', endTime: '19:40'),
  SectionTime(section: 10, startTime: '19:50', endTime: '20:30'),
];

class CourseTimeRange {
  const CourseTimeRange({required this.startTime, required this.endTime});

  final String startTime;
  final String endTime;

  String get label => '$startTime-$endTime';
}

class CourseTimeService {
  const CourseTimeService();

  static const _earlyBuildings = ['明志楼', '明德楼', '至善楼'];

  CourseTimeRange? resolve(
    Course course, {
    List<SectionTime> sectionTimes = officialSectionTimes,
  }) {
    final indexed = {for (final value in sectionTimes) value.section: value};
    final early = _earlyBuildings.any(course.classroom.contains);
    final start =
        _nonEmpty(course.startTime) ??
        _startFor(course.startSection, indexed, early);
    final end =
        _nonEmpty(course.endTime) ?? _endFor(course.endSection, indexed, early);
    if (start == null || end == null) return null;
    return CourseTimeRange(startTime: start, endTime: end);
  }

  String? _startFor(int section, Map<int, SectionTime> indexed, bool early) {
    if (early && section == 3) return '10:15';
    if (early && section == 4) return '11:05';
    return indexed[section]?.startTime;
  }

  String? _endFor(int section, Map<int, SectionTime> indexed, bool early) {
    if (early && section == 3) return '10:55';
    if (early && section == 4) return '11:45';
    return indexed[section]?.endTime;
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
