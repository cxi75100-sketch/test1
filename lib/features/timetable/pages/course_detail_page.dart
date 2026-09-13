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
                _CourseHero(
                  name: value.name,
                  classroom: value.classroom,
                  weekdayLabel: '周${_weekday(value.weekday)}',
                  startSection: value.startSection,
                  endSection: value.endSection,
                  accent: color,
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

class _CourseHero extends StatelessWidget {
  const _CourseHero({
    required this.name,
    required this.classroom,
    required this.weekdayLabel,
    required this.startSection,
    required this.endSection,
    required this.accent,
  });

  final String name;
  final String classroom;
  final String weekdayLabel;
  final int startSection;
  final int endSection;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? scheme.surfaceContainerHigh : scheme.surface;
    final sectionLabel = startSection == endSection
        ? '$startSection 节'
        : '$startSection-$endSection 节';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: courseSurfaceTint(accent, base, isDark: isDark),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: courseBadgeTint(accent),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$weekdayLabel · $sectionLabel',
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          if (classroom.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              classroom,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
            ),
          ],
          const SizedBox(height: 18),
          _SectionRoute(
            accent: accent,
            startSection: startSection,
            endSection: endSection,
          ),
        ],
      ),
    );
  }
}

/// 把课程占用的节次画成线路：一天十站在线，属于本课程的站点画实心。
///
/// 与整周列的站点连线同一套语言，让「这门课落在一天的哪一段」一眼可读。
class _SectionRoute extends StatelessWidget {
  const _SectionRoute({
    required this.accent,
    required this.startSection,
    required this.endSection,
  });

  final Color accent;
  final int startSection;
  final int endSection;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 18,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Center(
            child: SizedBox(
              width: double.infinity,
              height: 1.5,
              child: ColoredBox(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        ),
        Row(
          children: [
            for (final sectionTime in officialSectionTimes)
              Expanded(
                child: Center(child: _station(context, sectionTime.section)),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _station(BuildContext context, int section) {
    final scheme = Theme.of(context).colorScheme;
    final active = section >= startSection && section <= endSection;
    return Container(
      key: ValueKey('detail-section-station-$section'),
      width: active ? 10 : 7,
      height: active ? 10 : 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? accent : Colors.transparent,
        border: active
            ? null
            : Border.all(color: scheme.outlineVariant, width: 1.4),
      ),
    );
  }
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
