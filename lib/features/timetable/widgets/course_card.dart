import 'package:flutter/material.dart';

import '../../../core/theme/course_colors.dart';
import '../../../models/course.dart';
import '../../../services/course_time_service.dart';

/// 今日列表里的课程卡。
///
/// 与整周列的窄课卡共用同一套课程面与节次签（见 [courseSurfaceTint] /
/// [courseBadgeTint]），只是宽屏下多一层教室与教师的图标信息。
class CourseCard extends StatelessWidget {
  const CourseCard({
    required this.course,
    required this.onTap,
    this.compact = false,
    super.key,
  });

  final Course course;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = courseColorFor(course.colorKey);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = scheme.onSurfaceVariant;
    final time = const CourseTimeService().resolve(course);
    final radius = BorderRadius.circular(16);
    final base = isDark ? scheme.surfaceContainerHigh : scheme.surface;
    final sectionLabel = course.startSection == course.endSection
        ? '${course.startSection}节'
        : '${course.startSection}-${course.endSection}节';
    return Container(
      key: ValueKey('today-course-card-${course.id}'),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: courseSurfaceTint(color, base, isDark: isDark),
            ),
            borderRadius: radius,
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 16,
                vertical: compact ? 12 : 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              key: ValueKey(
                                'today-course-section-${course.id}',
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: courseBadgeTint(color),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                sectionLabel,
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontSize: 11,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (time != null) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  time.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 11,
                                    height: 1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: compact ? 7 : 9),
                        Text(
                          course.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: compact ? 15 : 16.5,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (course.classroom.isNotEmpty ||
                            course.teacher.isNotEmpty) ...[
                          SizedBox(height: compact ? 6 : 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 5,
                            children: [
                              if (course.classroom.isNotEmpty)
                                _Meta(
                                  icon: Icons.location_on_outlined,
                                  label: course.classroom,
                                  color: muted,
                                ),
                              if (course.teacher.isNotEmpty)
                                _Meta(
                                  icon: Icons.person_outline_rounded,
                                  label: course.teacher,
                                  color: muted,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 150),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ),
    ],
  );
}
