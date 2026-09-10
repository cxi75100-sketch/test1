import '../../../models/course.dart';

/// 一次导入相对上一次导入的变化。
///
/// 只反映教务来源课程：手动添加的课程不参与替换，也不应出现在差异里。
class ImportDiff {
  const ImportDiff({required this.added, required this.removed});

  /// 本次出现、上次没有的课程安排。
  final List<Course> added;

  /// 上次有、本次消失的课程安排。
  final List<Course> removed;

  bool get isEmpty => added.isEmpty && removed.isEmpty;
}

/// 比较上一次与本次的教务课程，得出新增与移除。
///
/// 按 `Course.id` 比对。解析器生成的 id 取自「教学班 + 节次 + 周次」指纹，
/// 同一门课跨次导入 id 稳定，因此 id 差异等同于课表内容差异。
///
/// [previous] 可以包含手动课程，本函数自行过滤，避免调用方误用。
ImportDiff diffImportedCourses({
  required List<Course> previous,
  required List<Course> next,
}) {
  final previousImported = previous.where(
    (course) => course.source == CourseSource.ncpu,
  );
  final previousIds = {for (final course in previousImported) course.id};
  final nextIds = {for (final course in next) course.id};
  return ImportDiff(
    added: [
      for (final course in next)
        if (!previousIds.contains(course.id)) course,
    ],
    removed: [
      for (final course in previousImported)
        if (!nextIds.contains(course.id)) course,
    ],
  );
}
