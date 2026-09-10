import 'dart:convert';

import '../../../core/theme/course_colors.dart';
import '../../../models/course.dart';
import 'week_parser.dart';

/// 课表数据无法解析。
class TimetableParseException implements Exception {
  const TimetableParseException(this.message);

  final String message;

  @override
  String toString() => 'TimetableParseException: $message';
}

/// 正方教务学生课表解析器。
///
/// 输入是 `/jwglxt/kbcx/xskbcx_cxXsgrkb.html` 的响应 JSON（接口形状经真机脱敏
/// 采集确认，见 `knowledge/ncpu_import.md`）。
///
/// 安全约定：只读取课表相关字段，**不读取 `xsxx` 中的姓名、学号、班级、专业等
/// 身份信息**；`kbList` 字段顺序不固定，全部按 key 取值。
class NcpuTimetableParser {
  const NcpuTimetableParser();

  /// 用于识别课表数据请求的端点标识。
  static const String endpointMarker = 'xskbcx_cxXsgrkb';

  /// 解析课表响应。
  ///
  /// 抛 [TimetableParseException] 表示响应不可用（登录失效、结构变化或该学期无课），
  /// 调用方应把消息展示给用户，不得静默吞掉。
  List<Course> parse(String rawResponse, {required String semesterId}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(rawResponse);
    } on FormatException catch (error) {
      throw TimetableParseException('课表数据不是合法 JSON（${error.message}）');
    }
    if (decoded is! Map) {
      throw const TimetableParseException('课表数据格式异常，登录可能已失效，请重新登录后再试');
    }
    final entries = decoded['kbList'];
    if (entries is! List) {
      throw const TimetableParseException('课表数据缺少 kbList 字段，登录可能已失效');
    }

    final courses = <Course>[];
    final seenIds = <String>{};
    for (final entry in entries) {
      if (entry is! Map) continue;
      final course = _courseFromEntry(entry, semesterId);
      if (course == null) continue;
      if (seenIds.add(course.id)) courses.add(course);
    }
    if (courses.isEmpty) {
      throw const TimetableParseException('没有解析出课程，该学期可能尚未排课');
    }
    courses.sort(
      (a, b) => a.weekday != b.weekday
          ? a.weekday.compareTo(b.weekday)
          : a.startSection.compareTo(b.startSection),
    );
    return courses;
  }

  Course? _courseFromEntry(Map<dynamic, dynamic> entry, String semesterId) {
    final name = _text(entry['kcmc']);
    if (name.isEmpty) return null;

    final weekday = int.tryParse(_text(entry['xqj']));
    if (weekday == null || weekday < 1 || weekday > 7) return null;

    final sections = _parseSections(entry);
    if (sections == null) return null;

    final weeks = _parseWeeks(_text(entry['zcd']));
    if (weeks.isEmpty) return null;

    final teachingClass = _text(entry['jxb_id']);
    final courseCode = _text(entry['kch']);
    final identifier = teachingClass.isNotEmpty ? teachingClass : courseCode;
    final start = sections.$1;
    final end = sections.$2;
    // 同一教学班同一节次可能因周次不同而分成多行（例如前半学期与后半学期
    // 换教室），因此 id 必须带上周次指纹，否则会互相覆盖、丢课。
    final weekSignature = weeks.fold<int>(0, (hash, week) => (hash * 31 + week) & 0x7fffffff);

    return Course(
      id: 'ncpu-$identifier-$weekday-$start-$end-$weekSignature',
      name: name,
      teacher: _text(entry['xm']),
      classroom: _text(entry['cdmc']),
      weekday: weekday,
      startSection: start,
      endSection: end,
      weeks: weeks,
      semesterId: semesterId,
      colorKey: courseColorKeyForName(name),
      note: _note(entry),
      source: CourseSource.ncpu,
    );
  }

  /// 节次：优先 `jcs`（`"3-4"`），退回 `jcor`、`jc`（`"3-4节"`）。
  (int, int)? _parseSections(Map<dynamic, dynamic> entry) {
    for (final key in const ['jcs', 'jcor', 'jc']) {
      final raw = _text(entry[key]).replaceAll('节', '').trim();
      if (raw.isEmpty) continue;
      final parts = raw.split('-');
      final start = int.tryParse(parts.first.trim());
      if (start == null || start < 1) continue;
      final end = parts.length > 1
          ? int.tryParse(parts[1].trim()) ?? start
          : start;
      if (end < start) continue;
      return (start, end);
    }
    return null;
  }

  List<int> _parseWeeks(String raw) {
    if (raw.isEmpty) return const [];
    try {
      return parseWeeks(raw);
    } on WeekParseException {
      return const [];
    }
  }

  String _note(Map<dynamic, dynamic> entry) {
    final parts = <String>[];
    final credit = _text(entry['xf']);
    if (credit.isNotEmpty) parts.add('学分 $credit');
    final nature = _text(entry['kcxz']);
    if (nature.isNotEmpty) parts.add(nature);
    return parts.join(' · ');
  }

  String _text(Object? value) {
    if (value == null) return '';
    final text = value.toString().trim();
    return text == 'null' ? '' : text;
  }
}
