import '../../../models/course.dart';
import '../parsers/week_parser.dart';

/// 与课表页一致的星期名（下标 0 为周一）。
const weekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

/// 同一 id 下单个字段的旧值与新值。
class CourseFieldChange {
  const CourseFieldChange({
    required this.label,
    required this.oldValue,
    required this.newValue,
  });

  /// 面向用户的字段名，如「教师」。
  final String label;

  /// 上一次导入的值。空字符串表示该字段未填，占位文案由 UI 决定。
  final String oldValue;

  /// 本次导入的值。
  final String newValue;
}

/// 同一 id 的课程详情变化。
///
/// 同时保留旧课程与新课程：UI 需要用旧值定位变化，用新值展示结果。
class CourseChange {
  const CourseChange({
    required this.previous,
    required this.current,
    required this.fields,
  });

  /// 上一次导入的课程。
  final Course previous;

  /// 本次导入的课程。
  final Course current;

  /// 发生变化的字段，至少一条。
  final List<CourseFieldChange> fields;
}

/// 一次导入相对上一次导入的变化。
///
/// 只反映教务来源课程：手动添加的课程不参与替换，也不应出现在差异里。
class ImportDiff {
  const ImportDiff({
    required this.added,
    required this.removed,
    this.changed = const [],
  });

  /// 本次出现、上次没有的课程安排。
  final List<Course> added;

  /// 上次有、本次消失的课程安排。
  final List<Course> removed;

  /// 同一 id 但详情发生变化的课程安排。
  ///
  /// 只计入这里，不再同时计入 [added] 或 [removed]。
  final List<CourseChange> changed;

  bool get isEmpty => added.isEmpty && removed.isEmpty && changed.isEmpty;
}

/// 比较上一次与本次的教务课程，得出新增、移除与详情变化。
///
/// 两侧都只取 `CourseSource.ncpu`：手动课程既不会被导入替换，也不该出现在差异里。
///
/// 新增/移除按 [Course.id] 判定；id 相同的课程再逐字段比较内容，
/// 因此教务调整课程名、教师、教室、周次等详情时同样会被用户看到。
ImportDiff diffImportedCourses({
  required List<Course> previous,
  required List<Course> next,
}) {
  final previousImported = [
    for (final course in previous)
      if (course.source == CourseSource.ncpu) course,
  ];
  final previousById = {
    for (final course in previousImported) course.id: course,
  };
  final nextImported = [
    for (final course in next)
      if (course.source == CourseSource.ncpu) course,
  ];
  final nextIds = {for (final course in nextImported) course.id};

  final changed = <CourseChange>[];
  for (final course in nextImported) {
    final previousCourse = previousById[course.id];
    if (previousCourse == null) continue;
    final fields = courseFieldChanges(previousCourse, course);
    if (fields.isEmpty) continue;
    changed.add(
      CourseChange(previous: previousCourse, current: course, fields: fields),
    );
  }

  return ImportDiff(
    added: [
      for (final course in nextImported)
        if (!previousById.containsKey(course.id)) course,
    ],
    removed: [
      for (final course in previousImported)
        if (!nextIds.contains(course.id)) course,
    ],
    changed: changed,
  );
}

/// 逐字段比较同一 id 的两条课程，返回内容不同的字段。
///
/// 比较的是值而不是对象引用：[Course.weeks] 逐项比较，教师、教室等空值也参与比较。
List<CourseFieldChange> courseFieldChanges(Course previous, Course current) {
  final changes = <CourseFieldChange>[];
  void add(String label, String oldValue, String newValue) {
    if (oldValue == newValue) return;
    changes.add(
      CourseFieldChange(label: label, oldValue: oldValue, newValue: newValue),
    );
  }

  add('课程名', previous.name, current.name);
  add('教师', previous.teacher, current.teacher);
  add('教室', previous.classroom, current.classroom);
  add('星期', _weekdayLabel(previous), _weekdayLabel(current));
  add('节次', _sectionLabel(previous), _sectionLabel(current));
  if (!_sameWeeks(previous.weeks, current.weeks)) {
    changes.add(
      CourseFieldChange(
        label: '周次',
        oldValue: formatWeeks(previous.weeks),
        newValue: formatWeeks(current.weeks),
      ),
    );
  }
  add('时间', _timeLabel(previous), _timeLabel(current));
  add('备注', previous.note, current.note);
  return changes;
}

String _weekdayLabel(Course course) =>
    course.weekday >= 1 && course.weekday <= weekdayLabels.length
    ? weekdayLabels[course.weekday - 1]
    : '星期${course.weekday}';

String _sectionLabel(Course course) => course.startSection == course.endSection
    ? '第 ${course.startSection} 节'
    : '第 ${course.startSection}-${course.endSection} 节';

String _timeLabel(Course course) {
  final start = course.startTime;
  final end = course.endTime;
  if (start == null && end == null) return '';
  return '${start ?? '?'}-${end ?? '?'}';
}

bool _sameWeeks(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
