import 'package:flutter/material.dart';

import '../../../core/theme/course_colors.dart';
import '../../../models/course.dart';
import '../../../services/course_time_service.dart';

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
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final time = const CourseTimeService().resolve(course);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: compact ? 48 : 58,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
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
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      course.startSection == course.endSection
                          ? '${course.startSection}节'
                          : '${course.startSection}-${course.endSection}节',
                      style: TextStyle(
                        color: color.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    if (time != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        time.label,
                        style: TextStyle(
                          color: color.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
      Icon(icon, size: 15, color: color),
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
