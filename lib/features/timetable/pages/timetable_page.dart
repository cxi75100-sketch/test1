import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/course_colors.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../models/course.dart';
import '../../../models/semester.dart';
import '../../../services/course_time_service.dart';
import '../../../services/semester_service.dart';
import '../providers/timetable_providers.dart';
import '../widgets/course_card.dart';

enum _ScheduleView { today, week }

class TimetablePage extends ConsumerStatefulWidget {
  const TimetablePage({super.key});

  static const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  ConsumerState<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends ConsumerState<TimetablePage> {
  _ScheduleView _view = _ScheduleView.today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semester = ref.watch(activeSemesterProvider);
    final week = ref.watch(selectedWeekProvider);
    final courses = ref.watch(visibleCoursesProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 82,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppPalette.ink,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2618213D),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Text(
                '课',
                style: TextStyle(
                  color: AppPalette.sun,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '南工课表',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 21,
                    ),
                  ),
                  Text(
                    semester?.name ?? '正在加载学期…',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '新增课程',
            onPressed: () => context.push('/course/new'),
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppPalette.sun,
              foregroundColor: AppPalette.ink,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: '设置',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.tune_rounded),
            style: IconButton.styleFrom(
              backgroundColor: scheme.surface,
              foregroundColor: scheme.onSurface,
              side: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: AmbientBackground(
        child: courses.when(
          data: (items) => _ScheduleBody(
            semester: semester,
            week: week,
            courses: items,
            view: _view,
            onViewChanged: _changeView,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _ErrorState(
            message: '$error',
            onRetry: () => ref.invalidate(visibleCoursesProvider),
          ),
        ),
      ),
    );
  }

  void _changeView(_ScheduleView value) {
    if (_view == value) return;
    if (value == _ScheduleView.today) {
      ref.read(selectedWeekProvider.notifier).goToCurrent();
    }
    setState(() => _view = value);
  }
}

class _ScheduleBody extends ConsumerWidget {
  const _ScheduleBody({
    required this.semester,
    required this.week,
    required this.courses,
    required this.view,
    required this.onViewChanged,
  });

  final Semester? semester;
  final int week;
  final List<Course> courses;
  final _ScheduleView view;
  final ValueChanged<_ScheduleView> onViewChanged;

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
    return Column(
      children: [
        _ScheduleViewSwitcher(value: view, onChanged: onViewChanged),
        if (termStatus != TermStatus.within && activeSemester != null)
          _TermHintBanner(semester: activeSemester, status: termStatus),
        if (view == _ScheduleView.today)
          Expanded(
            child: _TodaySchedule(
              week: week,
              totalWeeks: totalWeeks,
              courses: courses,
              termStatus: termStatus,
              onOpenWeek: () => onViewChanged(_ScheduleView.week),
            ),
          )
        else ...[
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
          Expanded(
            child: courses.isEmpty
                ? const _EmptyState(
                    title: '本周暂无课程',
                    message: '可以手动新增，或到设置里从教务系统导入',
                  )
                : _WeekBoard(semester: semester, week: week, courses: courses),
          ),
        ],
      ],
    );
  }
}

class _ScheduleViewSwitcher extends StatelessWidget {
  const _ScheduleViewSwitcher({required this.value, required this.onChanged});

  final _ScheduleView value;
  final ValueChanged<_ScheduleView> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('schedule-view-switcher'),
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppPalette.ink,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppPalette.ink),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2418213D),
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: _ScheduleViewButton(
            key: const ValueKey('today-view-button'),
            label: '今日',
            icon: Icons.today_rounded,
            selected: value == _ScheduleView.today,
            onTap: () => onChanged(_ScheduleView.today),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _ScheduleViewButton(
            key: const ValueKey('week-view-button'),
            label: '整周',
            icon: Icons.calendar_view_week_rounded,
            selected: value == _ScheduleView.week,
            onTap: () => onChanged(_ScheduleView.week),
          ),
        ),
      ],
    ),
  );
}

class _ScheduleViewButton extends StatelessWidget {
  const _ScheduleViewButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected ? scheme.onSurface : Colors.white70,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? scheme.onSurface : Colors.white70,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodaySchedule extends StatelessWidget {
  const _TodaySchedule({
    required this.week,
    required this.totalWeeks,
    required this.courses,
    required this.termStatus,
    required this.onOpenWeek,
  });

  final int week;
  final int totalWeeks;
  final List<Course> courses;
  final TermStatus termStatus;
  final VoidCallback onOpenWeek;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayCourses = termStatus == TermStatus.within
        ? (courses.where((course) => course.weekday == now.weekday).toList()
            ..sort((a, b) => a.startSection.compareTo(b.startSection)))
        : <Course>[];
    return ListView(
      key: const ValueKey('today-schedule'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        _TodayHero(
          date: now,
          week: week,
          totalWeeks: totalWeeks,
          courseCount: todayCourses.length,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Text(
              '今日课程',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text(
              '${todayCourses.length} 门',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (todayCourses.isEmpty) ...[
          const _FreeDayPanel(),
          const SizedBox(height: 12),
          _QuickActions(onOpenWeek: onOpenWeek),
        ] else
          ...todayCourses.map(
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
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.date,
    required this.week,
    required this.totalWeeks,
    required this.courseCount,
  });

  final DateTime date;
  final int week;
  final int totalWeeks;
  final int courseCount;

  @override
  Widget build(BuildContext context) {
    final progress = (week / totalWeeks).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.ink,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3318213D),
            blurRadius: 22,
            offset: Offset(0, 11),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -22,
            top: -28,
            child: Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(
                color: AppPalette.coral,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 22,
            top: 20,
            child: Transform.rotate(
              angle: -0.12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.sun,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$courseCount 门课',
                  style: const TextStyle(
                    color: AppPalette.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TODAY / CAMPUS',
                  style: TextStyle(
                    color: AppPalette.mint,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${date.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        height: 0.9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${date.month}月 · ${TimetablePage.weekdays[date.weekday - 1]}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '第 $week 周 / 共 $totalWeeks 周',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text(
                      '学期进度',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 7,
                          value: progress,
                          color: AppPalette.mint,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: AppPalette.sun,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeDayPanel extends StatelessWidget {
  const _FreeDayPanel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FREE DAY',
                  style: TextStyle(
                    color: AppPalette.coral,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '今天没有课程',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text('把空白留给休息，或提前看看下一站。', style: TextStyle(height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const _PlannerIllustration(),
        ],
      ),
    );
  }
}

class _PlannerIllustration extends StatelessWidget {
  const _PlannerIllustration();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 92,
    height: 82,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -0.13,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppPalette.sun,
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: SizedBox(width: 68, height: 66),
          ),
        ),
        Transform.rotate(
          angle: 0.08,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppPalette.cobalt,
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: SizedBox(
              width: 68,
              height: 66,
              child: Icon(
                Icons.local_cafe_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpenWeek});

  final VoidCallback onOpenWeek;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('empty-quick-actions'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.calendar_view_week_rounded,
              label: '查看整周',
              color: AppPalette.cobalt,
              onTap: onOpenWeek,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickAction(
              icon: Icons.add_circle_outline_rounded,
              label: '新增课程',
              color: AppPalette.coral,
              onTap: () => context.push('/course/new'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickAction(
              icon: Icons.cloud_download_outlined,
              label: '教务导入',
              color: AppPalette.mint,
              onTap: () => context.push('/import/login'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 13),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
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
        colors: [AppPalette.ink, Color(0xFF29355E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x3318213D),
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
                      color: AppPalette.mint,
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

class _WeekBoard extends StatelessWidget {
  const _WeekBoard({
    required this.semester,
    required this.week,
    required this.courses,
  });

  final Semester? semester;
  final int week;
  final List<Course> courses;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columnWidth = ((constraints.maxWidth - 42) / 2.25)
          .clamp(142.0, 168.0)
          .toDouble();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 9),
            child: Row(
              children: [
                Icon(
                  Icons.swipe_left_alt_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 7),
                Text(
                  '横向滑动查看一周 · 每天上下各半',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('week-board-scroll'),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 88, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(7, (index) {
                  final weekday = index + 1;
                  final dayCourses =
                      courses
                          .where((course) => course.weekday == weekday)
                          .toList()
                        ..sort(
                          (a, b) => a.startSection.compareTo(b.startSection),
                        );
                  return Padding(
                    padding: EdgeInsets.only(right: index == 6 ? 0 : 10),
                    child: SizedBox(
                      width: columnWidth,
                      child: _WeekDayColumn(
                        weekday: weekday,
                        date: _dateFor(semester, week, weekday),
                        courses: dayCourses,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _WeekDayColumn extends StatelessWidget {
  const _WeekDayColumn({
    required this.weekday,
    required this.date,
    required this.courses,
  });

  final int weekday;
  final DateTime? date;
  final List<Course> courses;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isToday =
        date != null &&
        date!.year == now.year &&
        date!.month == now.month &&
        date!.day == now.day;
    final morning = courses
        .where((course) => course.startSection <= 4)
        .toList();
    final later = courses.where((course) => course.startSection >= 5).toList();
    return Container(
      key: ValueKey('week-day-column-$weekday'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isToday
              ? AppPalette.cobalt.withValues(alpha: 0.42)
              : scheme.outlineVariant,
          width: isToday ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D18213D),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _DayColumnHeader(
            weekday: weekday,
            date: date,
            courseCount: courses.length,
            isToday: isToday,
          ),
          Expanded(
            child: _DayHalf(
              key: ValueKey('day-$weekday-morning'),
              title: '上午',
              sectionLabel: '1–4 节',
              icon: Icons.wb_sunny_outlined,
              accent: AppPalette.cobalt,
              courses: morning,
              sectionBreaks: const [2, 4],
            ),
          ),
          const Divider(),
          Expanded(
            child: _DayHalf(
              key: ValueKey('day-$weekday-later'),
              title: '下午 / 晚间',
              sectionLabel: '5–10 节',
              icon: Icons.wb_twilight_outlined,
              accent: const Color(0xFFB86A32),
              courses: later,
              sectionBreaks: const [6, 8, 10],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayColumnHeader extends StatelessWidget {
  const _DayColumnHeader({
    required this.weekday,
    required this.date,
    required this.courseCount,
    required this.isToday,
  });

  final int weekday;
  final DateTime? date;
  final int courseCount;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      color: isToday
          ? AppPalette.sun.withValues(alpha: 0.15)
          : scheme.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TimetablePage.weekdays[weekday - 1],
                  style: TextStyle(
                    color: isToday ? scheme.primary : scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date == null ? '日期未设置' : '${date!.month}月${date!.day}日',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: isToday
                  ? scheme.primary.withValues(alpha: 0.1)
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$courseCount',
              style: TextStyle(
                color: isToday ? scheme.primary : scheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHalf extends StatelessWidget {
  const _DayHalf({
    required this.title,
    required this.sectionLabel,
    required this.icon,
    required this.accent,
    required this.courses,
    required this.sectionBreaks,
    super.key,
  });

  final String title;
  final String sectionLabel;
  final IconData icon;
  final Color accent;
  final List<Course> courses;
  final List<int> sectionBreaks;

  @override
  Widget build(BuildContext context) {
    final coursesBySlot = [
      for (var slotIndex = 0; slotIndex < sectionBreaks.length; slotIndex++)
        courses.where((course) {
          final previousBreak = slotIndex == 0
              ? 0
              : sectionBreaks[slotIndex - 1];
          return course.startSection > previousBreak &&
              course.startSection <= sectionBreaks[slotIndex];
        }).toList(),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(9, 9, 9, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                sectionLabel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Expanded(
            child: courses.isEmpty
                ? Center(
                    child: Text(
                      '无课',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 11,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (
                        var slotIndex = 0;
                        slotIndex < coursesBySlot.length;
                        slotIndex++
                      )
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: slotIndex == coursesBySlot.length - 1
                                  ? 0
                                  : 5,
                            ),
                            child: Column(
                              children: [
                                for (final course in coursesBySlot[slotIndex])
                                  Expanded(
                                    child: _GridCourseCard(course: course),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _GridCourseCard extends StatelessWidget {
  const _GridCourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final color = courseColorFor(course.colorKey);
    final time = const CourseTimeService().resolve(course);
    final sectionLabel = course.startSection == course.endSection
        ? '${course.startSection}节'
        : '${course.startSection}-${course.endSection}节';

    return LayoutBuilder(
      builder: (context, constraints) {
        final dense = constraints.maxHeight < 70;
        final cardRadius = BorderRadius.circular(dense ? 10 : 14);
        return Container(
          key: ValueKey('week-course-card-${course.id}'),
          decoration: BoxDecoration(
            borderRadius: cardRadius,
            boxShadow: [
              BoxShadow(
                color: Color.lerp(
                  AppPalette.ink,
                  color,
                  0.45,
                )!.withValues(alpha: 0.18),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: cardRadius,
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: courseGradientColors(color, strength: 0.62),
                ),
                borderRadius: cardRadius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
              ),
              child: InkWell(
                onTap: () => context.push('/course/${course.id}'),
                borderRadius: cardRadius,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: dense ? 6 : 8,
                    vertical: dense ? 5 : 7,
                  ),
                  child: constraints.maxHeight < 42
                      ? FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: _GridCourseTinyContent(
                            course: course,
                            sectionLabel: sectionLabel,
                            timeLabel: time?.label,
                          ),
                        )
                      : _GridCourseContent(
                          course: course,
                          sectionLabel: sectionLabel,
                          timeLabel: time?.label,
                          dense: dense,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridCourseTinyContent extends StatelessWidget {
  const _GridCourseTinyContent({
    required this.course,
    required this.sectionLabel,
    required this.timeLabel,
  });

  final Course course;
  final String sectionLabel;
  final String? timeLabel;

  @override
  Widget build(BuildContext context) {
    final hasMetadata =
        course.classroom.isNotEmpty || course.teacher.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: ValueKey('week-course-section-${course.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppPalette.sun,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                sectionLabel,
                style: TextStyle(
                  color: AppPalette.ink,
                  fontSize: 7,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (timeLabel != null) ...[
              const SizedBox(width: 3),
              Text(
                timeLabel!,
                style: const TextStyle(
                  color: Color(0xB8FFFFFF),
                  fontSize: 7,
                  height: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        if (hasMetadata) ...[
          const SizedBox(height: 2),
          DefaultTextStyle(
            style: const TextStyle(
              color: Color(0xB8FFFFFF),
              fontSize: 7,
              height: 1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (course.classroom.isNotEmpty) Text(course.classroom),
                if (course.classroom.isNotEmpty && course.teacher.isNotEmpty)
                  const Text(' · '),
                if (course.teacher.isNotEmpty) Text(course.teacher),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _GridCourseContent extends StatelessWidget {
  const _GridCourseContent({
    required this.course,
    required this.sectionLabel,
    required this.timeLabel,
    required this.dense,
  });

  final Course course;
  final String sectionLabel;
  final String? timeLabel;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final hasMetadata =
        course.classroom.isNotEmpty || course.teacher.isNotEmpty;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              key: ValueKey('week-course-section-${course.id}'),
              padding: EdgeInsets.symmetric(
                horizontal: dense ? 4 : 5,
                vertical: dense ? 2 : 2.5,
              ),
              decoration: BoxDecoration(
                color: AppPalette.sun,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(2),
                  topRight: const Radius.circular(7),
                  bottomLeft: const Radius.circular(7),
                  bottomRight: const Radius.circular(3),
                ),
              ),
              child: Text(
                sectionLabel,
                style: TextStyle(
                  color: AppPalette.ink,
                  fontSize: dense ? 7 : 7.5,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (timeLabel != null) ...[
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  timeLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: dense ? 7.5 : 8,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: dense ? 3 : 5),
        Text(
          course.name,
          maxLines: dense ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: dense ? 10 : 11.5,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.15,
          ),
        ),
        if (hasMetadata) ...[
          SizedBox(height: dense ? 2 : 4),
          DefaultTextStyle(
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: dense ? 7.5 : 8.5,
              height: 1,
              fontWeight: FontWeight.w500,
            ),
            child: Row(
              children: [
                if (course.classroom.isNotEmpty)
                  Flexible(
                    child: Text(
                      course.classroom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (course.classroom.isNotEmpty && course.teacher.isNotEmpty)
                  const Text(' · '),
                if (course.teacher.isNotEmpty)
                  Flexible(
                    child: Text(
                      course.teacher,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

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
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            message,
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
