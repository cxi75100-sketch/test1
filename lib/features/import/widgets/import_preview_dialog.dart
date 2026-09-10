import 'package:flutter/material.dart';

import '../../../models/course.dart';
import '../parsers/week_parser.dart';
import '../services/import_diff.dart';

/// 导入预览：把解析结果先展示给用户确认，再写入本地。
///
/// 只展示通用 [Course] 字段；教务系统的原始字段不进入 UI。
class ImportPreviewDialog extends StatelessWidget {
  const ImportPreviewDialog({
    required this.schoolName,
    required this.courses,
    this.diff,
    super.key,
  });

  final String schoolName;
  final List<Course> courses;

  /// 相对上一次导入的新增/移除。为空表示首次导入或无法比较。
  final ImportDiff? diff;

  /// 展示预览，返回用户是否确认导入。
  static Future<bool> show(
    BuildContext context, {
    required String schoolName,
    required List<Course> courses,
    ImportDiff? diff,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ImportPreviewDialog(
        schoolName: schoolName,
        courses: courses,
        diff: diff,
      ),
    );
    return confirmed ?? false;
  }

  static const _weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  Widget build(BuildContext context) {
    final summary = diff;
    return AlertDialog(
      title: Text('导入预览（${courses.length} 条安排）'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '来自 $schoolName 教务系统。确认后将写入本地课表，'
              '并替换上一次导入的课程（手动添加的课程不受影响）。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (summary != null && !summary.isEmpty) ...[
              const SizedBox(height: 12),
              _DiffSummary(diff: summary),
            ],
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: courses.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => _CourseRow(course: courses[index]),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '提示：周次要显示正确，请在「设置 → 学期设置」里填好开学第一周的周一。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('确认导入'),
        ),
      ],
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (course.classroom.isNotEmpty) course.classroom,
      if (course.teacher.isNotEmpty) course.teacher,
      formatWeeks(course.weeks),
    ].join(' · ');
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(course.name),
      subtitle: Text(details, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text(_slotLabel(course)),
    );
  }
}

/// 「新增/移除」摘要：让用户在按下确认前看见本次替换会带来什么变化。
class _DiffSummary extends StatelessWidget {
  const _DiffSummary({required this.diff});

  final ImportDiff diff;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '相对上次导入',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '新增 ${diff.added.length} 条 · 移除 ${diff.removed.length} 条',
            style: const TextStyle(fontSize: 13),
          ),
          if (diff.removed.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '将被移除：',
              style: TextStyle(fontSize: 12, color: scheme.error),
            ),
            ...diff.removed.map(
              (course) => Text(
                '· ${course.name}（${_slotLabel(course)}）',
                style: TextStyle(fontSize: 12, color: scheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 「周一 3-4节」这类定位串，供课程行与差异明细共用。
String _slotLabel(Course course) {
  final weekday = ImportPreviewDialog._weekdayNames[course.weekday - 1];
  final sections = course.startSection == course.endSection
      ? '${course.startSection}'
      : '${course.startSection}-${course.endSection}';
  return '$weekday $sections节';
}
