import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/course_colors.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../services/course_time_service.dart';
import '../../import/parsers/week_parser.dart';
import '../providers/timetable_providers.dart';

class CourseDetailPage extends ConsumerWidget {
  const CourseDetailPage({required this.courseId, super.key});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider(courseId));
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('课程详情'),
            Text(
              'COURSE CARD',
              style: TextStyle(
                color: AppPalette.coral,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '编辑',
            onPressed: () async {
              await context.push('/course/$courseId/edit');
              ref.invalidate(courseProvider(courseId));
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: '删除',
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: AmbientBackground(
        child: course.when(
          data: (value) {
            if (value == null) return const Center(child: Text('课程不存在或已删除'));
            final color = courseColorFor(value.colorKey);
            final time = const CourseTimeService().resolve(value)?.label ?? '';
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: courseGradientColors(color),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.24),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.sun,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '周${_weekday(value.weekday)} · ${value.startSection}-${value.endSection} 节',
                          style: TextStyle(
                            color: AppPalette.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        value.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      if (value.classroom.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          value.classroom,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Column(
                    children: [
                      _DetailTile(
                        icon: Icons.person_outline_rounded,
                        label: '教师',
                        value: value.teacher,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 60),
                        child: Divider(),
                      ),
                      _DetailTile(
                        icon: Icons.calendar_view_week_outlined,
                        label: '上课周次',
                        value: formatWeeks(value.weeks),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 60),
                        child: Divider(),
                      ),
                      _DetailTile(
                        icon: Icons.schedule_rounded,
                        label: '上课时间',
                        value: time,
                      ),
                    ],
                  ),
                ),
                if (value.note.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '备注',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(value.note, style: const TextStyle(height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('$error')),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除课程？'),
            content: const Text('删除后无法在 App 内撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    await ref.read(databaseProvider).deleteCourse(courseId);
    ref.invalidate(courseProvider(courseId));
    if (context.mounted) context.pop();
  }

  String _weekday(int value) =>
      const ['一', '二', '三', '四', '五', '六', '日'][value - 1];
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(label, style: const TextStyle(fontSize: 13)),
    subtitle: Text(
      value.isEmpty ? '未填写' : value,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  );
}
