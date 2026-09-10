import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/course.dart';
import '../../../models/semester.dart';
import '../../../services/semester_service.dart';
import '../providers/timetable_providers.dart';
import '../widgets/course_card.dart';

class TimetablePage extends ConsumerWidget {
  const TimetablePage({super.key});

  static const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semester = ref.watch(activeSemesterProvider);
    final week = ref.watch(selectedWeekProvider);
    final courses = ref.watch(visibleCoursesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '我的课表',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            Text(
              semester?.name ?? '正在加载学期…',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            tooltip: '设置',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: courses.when(
        data: (items) =>
            _ScheduleBody(semester: semester, week: week, courses: items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(visibleCoursesProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/course/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('新增课程'),
      ),
    );
  }
}

class _ScheduleBody extends ConsumerWidget {
  const _ScheduleBody({
    required this.semester,
    required this.week,
    required this.courses,
  });

  final Semester? semester;
  final int week;
  final List<Course> courses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSemester = semester;
    final totalWeeks = activeSemester?.totalWeeks ?? defaultTotalWeeks;
    // 学期日期和今天对不上时必须提示：currentWeek 会把超出的周次封顶到
    // totalWeeks，不提示的话用户只会看到周次一直停在第 N 周，以为课表没更新。
    // 学期尚未加载出来时按“正常”处理，避免加载瞬间闪一下提示。
    final termStatus = activeSemester == null
        ? TermStatus.within
        : const SemesterService().termStatus(activeSemester, DateTime.now());
    final counts = List.generate(
      7,
      (index) => courses.where((course) => course.weekday == index + 1).length,
    );
    return Column(
      children: [
        _WeekHero(
          week: week,
          totalWeeks: totalWeeks,
          courseCount: courses.length,
          onPrevious: week > 1
              ? ref.read(selectedWeekProvider.notifier).previous
              : null,
          onNext: week < totalWeeks
              ? () => ref.read(selectedWeekProvider.notifier).next(totalWeeks)
              : null,
          onCurrent: ref.read(selectedWeekProvider.notifier).goToCurrent,
        ),
        if (termStatus != TermStatus.within && activeSemester != null)
          _TermHintBanner(semester: activeSemester, status: termStatus),
        _WeekStrip(semester: semester, week: week, counts: counts),
        Expanded(
          child: courses.isEmpty
              ? const _EmptyState()
              : _AgendaList(semester: semester, week: week, courses: courses),
        ),
      ],
    );
  }
}

class _WeekHero extends StatelessWidget {
  const _WeekHero({
    required this.week,
    required this.totalWeeks,
    required this.courseCount,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
  });

  final int week;
  final int totalWeeks;
  final int courseCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onCurrent;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF405FD0), Color(0xFF6C63DB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x29405FD0),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            _HeroIconButton(
              tooltip: '上一周',
              onPressed: onPrevious,
              icon: Icons.chevron_left_rounded,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '第 $week 周',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '共 $totalWeeks 周 · 本周 $courseCount 条安排',
                    style: const TextStyle(
                      color: Color(0xFFDCE2FF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _HeroIconButton(
              tooltip: '下一周',
              onPressed: onNext,
              icon: Icons.chevron_right_rounded,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onCurrent,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          icon: const Icon(Icons.today_outlined, size: 17),
          label: const Text('回到本周'),
        ),
      ],
    ),
  );
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      foregroundColor: Colors.white,
      disabledForegroundColor: Colors.white38,
      backgroundColor: Colors.white.withValues(alpha: 0.12),
    ),
    icon: Icon(icon),
  );
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.semester,
    required this.week,
    required this.counts,
  });

  final Semester? semester;
  final int week;
  final List<int> counts;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 68,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: 7,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final date = _dateFor(semester, week, index + 1);
        final active = counts[index] > 0;
        return Container(
          width: 54,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.25)
                  : const Color(0xFFE7E9F1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                TimetablePage.weekdays[index].replaceFirst('周', ''),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                date == null ? '—' : '${date.month}/${date.day}',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// 学期日期与今天对不上时的提示条。
///
/// 没有这个提示时，学期设置过期的设备只会看到周次一直停在第 N 周，
/// 用户无法分辨是本地学期日期过期，还是课表没有更新。
class _TermHintBanner extends StatelessWidget {
  const _TermHintBanner({required this.semester, required this.status});

  final Semester semester;
  final TermStatus status;

  @override
  Widget build(BuildContext context) {
    final start = semester.firstWeekMonday;
    final message = status == TermStatus.before
        ? '今天早于学期开始日 ${start.month}月${start.day}日，周次按第 1 周显示。'
        : '今天已超出本学期 ${semester.totalWeeks} 周，周次会停在第 '
              '${semester.totalWeeks} 周。';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/settings'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$message\n点此更新学期设置。',
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.orange.shade800,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AgendaList extends StatelessWidget {
  const _AgendaList({
    required this.semester,
    required this.week,
    required this.courses,
  });

  final Semester? semester;
  final int week;
  final List<Course> courses;

  @override
  Widget build(BuildContext context) {
    final activeDays = List.generate(
      7,
      (index) => index + 1,
    ).where((day) => courses.any((course) => course.weekday == day)).toList();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
      itemCount: activeDays.length,
      separatorBuilder: (_, _) => const SizedBox(height: 22),
      itemBuilder: (context, index) {
        final weekday = activeDays[index];
        final dayCourses =
            courses.where((course) => course.weekday == weekday).toList()
              ..sort((a, b) => a.startSection.compareTo(b.startSection));
        return _DaySection(
          weekday: weekday,
          date: _dateFor(semester, week, weekday),
          courses: dayCourses,
        );
      },
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.weekday,
    required this.date,
    required this.courses,
  });

  final int weekday;
  final DateTime? date;
  final List<Course> courses;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          children: [
            Text(
              TimetablePage.weekdays[weekday - 1],
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            if (date != null)
              Text(
                '${date!.month}月${date!.day}日',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const Spacer(),
            Text(
              '${courses.length} 门',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      ...courses.map(
        (course) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CourseCard(
            course: course,
            onTap: () => context.push('/course/${course.id}'),
          ),
        ),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 72),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '本周暂无课程',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            '可以手动新增，或到设置里从教务系统导入',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 10),
          const Text('课表加载失败', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    ),
  );
}

/// 第 [week] 周星期 [weekday] 的日期；日期算法统一放在 [SemesterService]。
DateTime? _dateFor(Semester? semester, int week, int weekday) {
  if (semester == null) return null;
  return const SemesterService().dateFor(semester, week, weekday);
}
