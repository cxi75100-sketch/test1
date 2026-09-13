import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 64,
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.onSurface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: CustomPaint(
                  painter: _RouteMarkPainter(
                    line: scheme.surface,
                    station: scheme.tertiary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '南工课表',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 21,
                        letterSpacing: -0.6,
                      ),
                    ),
                    Text(
                      semester?.name ?? '正在加载学期…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '设置',
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.tune_rounded),
              style: IconButton.styleFrom(
                backgroundColor: scheme.surfaceContainerLow,
                foregroundColor: scheme.onSurface,
                side: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: courses.when(
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: const ValueKey('schedule-view-switcher'),
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
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
    final selectedForeground = scheme.onSurface;
    final idleForeground = scheme.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          // 整条栏目按钮固定 48dp 高，文字行在剩余空间内居中，指示条压底边。
          child: SizedBox(
            height: 48,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: selected ? scheme.primary : idleForeground,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        label,
                        style: TextStyle(
                          color: selected ? selectedForeground : idleForeground,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: selected ? 42 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
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

class _RouteMarkPainter extends CustomPainter {
  const _RouteMarkPainter({required this.line, required this.station});

  final Color line;
  final Color station;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.72)
      ..lineTo(size.width * 0.48, size.height * 0.46)
      ..lineTo(size.width * 0.76, size.height * 0.23);
    canvas.drawPath(
      path,
      Paint()
        ..color = line.withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    final dotPaint = Paint()..color = station;
    for (final point in [
      Offset(size.width * 0.22, size.height * 0.72),
      Offset(size.width * 0.48, size.height * 0.46),
      Offset(size.width * 0.76, size.height * 0.23),
    ]) {
      canvas.drawCircle(point, 3.4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RouteMarkPainter oldDelegate) =>
      oldDelegate.line != line || oldDelegate.station != station;
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 58,
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 42,
                height: 1,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.5,
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
                  '${date.month}月 · ${TimetablePage.weekdays[date.weekday - 1]}',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '第 $week 周，共 $totalWeeks 周',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$courseCount 门课',
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_outlined,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '今天没有课程',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '可以看看整周安排，或新增一门课',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpenWeek});

  final VoidCallback onOpenWeek;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('empty-quick-actions'),
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.calendar_view_week_rounded,
              label: '查看整周',
              onTap: onOpenWeek,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickAction(
              icon: Icons.add_circle_outline_rounded,
              label: '新增课程',
              onTap: () => context.push('/course/new'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickAction(
              icon: Icons.cloud_download_outlined,
              label: '教务导入',
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 13),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: scheme.primary),
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: Row(
        children: [
          _HeroIconButton(
            tooltip: '上一周',
            onPressed: onPrevious,
            icon: Icons.chevron_left_rounded,
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '第 $week 教学周',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 18,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$courseCount 门课程 · 全学期 $totalWeeks 周',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCurrent,
            style: TextButton.styleFrom(
              foregroundColor: scheme.primary,
              backgroundColor: scheme.primary.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 11),
              minimumSize: const Size(0, 36),
            ),
            child: const Text(
              '本周',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          _HeroIconButton(
            tooltip: '下一周',
            onPressed: onNext,
            icon: Icons.chevron_right_rounded,
          ),
        ],
      ),
    );
  }
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
      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      disabledForegroundColor: Theme.of(context).colorScheme.onSurfaceVariant
          .withValues(alpha: 0.35),
    ),
    icon: Icon(icon),
  );
}

/*
 * The week navigation intentionally stays outside the day cards. Keeping it
 * here prevents the timetable itself from being pushed down by a second hero.
 */

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
        color: Theme.of(context).colorScheme.tertiaryContainer,
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
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$message\n点此更新学期设置。',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekBoard extends StatefulWidget {
  const _WeekBoard({
    required this.semester,
    required this.week,
    required this.courses,
  });

  final Semester? semester;
  final int week;
  final List<Course> courses;

  @override
  State<_WeekBoard> createState() => _WeekBoardState();
}

class _WeekBoardState extends State<_WeekBoard> {
  static const _columnGap = 10.0;

  final ScrollController _scrollController = ScrollController();
  int? _positionedWeek;
  int _activeRouteIndex = 0;
  double _columnExtent = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncActiveRoute);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncActiveRoute);
    _scrollController.dispose();
    super.dispose();
  }

  void _syncActiveRoute() {
    if (_columnExtent <= 0 || !_scrollController.hasClients) return;
    final next = (_scrollController.offset / _columnExtent).round().clamp(0, 6);
    if (next != _activeRouteIndex && mounted) {
      setState(() => _activeRouteIndex = next);
    }
  }

  void _jumpToRoute(int index) {
    if (!_scrollController.hasClients || _columnExtent <= 0) return;
    _scrollController.animateTo(
      (index * _columnExtent).clamp(
        0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  bool get _selectedWeekContainsToday {
    final now = DateTime.now();
    final selectedDate = _dateFor(widget.semester, widget.week, now.weekday);
    return selectedDate != null &&
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  List<int> get _weekdayOrder {
    if (!_selectedWeekContainsToday) return const [1, 2, 3, 4, 5, 6, 7];
    final today = DateTime.now().weekday;
    return [
      for (var offset = 0; offset < 7; offset++) (today + offset - 1) % 7 + 1,
    ];
  }

  void _positionAtStart() {
    if (_positionedWeek == widget.week) return;
    _positionedWeek = widget.week;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // 首屏完整展示两天并露出下一列边缘。当前周从今天开始循环排列，
      // 避免用户先手动滑到当天；其他周仍保持周一到周日。
      final columnWidth = ((constraints.maxWidth - 50) / 2)
          .clamp(156.0, 220.0)
          .toDouble();
      _columnExtent = columnWidth + _columnGap;
      _positionAtStart();
      final trailingPadding = (constraints.maxWidth - 16 - columnWidth)
          .clamp(16.0, double.infinity)
          .toDouble();
      final weekdayOrder = _weekdayOrder;
      return Column(
        children: [
          _WeekRouteStrip(
            weekdayOrder: weekdayOrder,
            activeIndex: _activeRouteIndex,
            semester: widget.semester,
            week: widget.week,
            courses: widget.courses,
            onSelected: _jumpToRoute,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('week-board-scroll'),
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 0, trailingPadding, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(7, (index) {
                  final weekday = weekdayOrder[index];
                  final dayCourses =
                      widget.courses
                          .where((course) => course.weekday == weekday)
                          .toList()
                        ..sort(
                          (a, b) => a.startSection.compareTo(b.startSection),
                        );
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == weekdayOrder.length - 1 ? 0 : _columnGap,
                    ),
                    child: SizedBox(
                      width: columnWidth,
                      child: _WeekDayColumn(
                        weekday: weekday,
                        date: _dateFor(widget.semester, widget.week, weekday),
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

class _WeekRouteStrip extends StatelessWidget {
  const _WeekRouteStrip({
    required this.weekdayOrder,
    required this.activeIndex,
    required this.semester,
    required this.week,
    required this.courses,
    required this.onSelected,
  });

  final List<int> weekdayOrder;
  final int activeIndex;
  final Semester? semester;
  final int week;
  final List<Course> courses;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '整周路线图，可点击日期定位',
      child: SizedBox(
        key: const ValueKey('week-route-strip'),
        height: 68,
        child: Stack(
          children: [
            Positioned(
              left: 32,
              right: 32,
              top: 30,
              child: Container(height: 2, color: scheme.outlineVariant),
            ),
            Row(
              children: List.generate(weekdayOrder.length, (index) {
                final weekday = weekdayOrder[index];
                final date = _dateFor(semester, week, weekday);
                final count = courses
                    .where((course) => course.weekday == weekday)
                    .length;
                final selected = index == activeIndex;
                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label:
                        '${TimetablePage.weekdays[weekday - 1]}，${date == null ? '日期未设置' : '${date.month}月${date.day}日'}，$count 门课',
                    child: InkResponse(
                      key: ValueKey('week-route-day-$weekday'),
                      onTap: () => onSelected(index),
                      radius: 28,
                      child: Column(
                        children: [
                          Text(
                            index == 0 && _isToday(date)
                                ? '今天'
                                : TimetablePage.weekdays[weekday - 1]
                                      .replaceFirst('周', ''),
                            style: TextStyle(
                              color: selected
                                  ? scheme.onSurface
                                  : scheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: selected ? 18 : 11,
                            height: selected ? 18 : 11,
                            decoration: BoxDecoration(
                              color: selected
                                  ? (_isToday(date)
                                        ? scheme.tertiary
                                        : scheme.primary)
                                  : scheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? scheme.surface
                                    : scheme.outline,
                                width: selected ? 3 : 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$count',
                            style: TextStyle(
                              color: selected
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isToday(DateTime? date) {
  if (date == null) return false;
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
    // 空日不画整列卡片：只留两条极淡的列轨，让「今天没课」读到的是线路上
    // 没有站点，而不是一张巨大的空白卡。
    final hasCourses = courses.isNotEmpty;
    return Container(
      key: ValueKey('week-day-column-$weekday'),
      clipBehavior: Clip.antiAlias,
      decoration: hasCourses
          ? BoxDecoration(
              color: scheme.surface.withValues(alpha: isDark ? 0.58 : 0.72),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              border: Border.symmetric(
                vertical: BorderSide(
                  color: scheme.outlineVariant.withValues(
                    alpha: isDark ? 0.72 : 1,
                  ),
                ),
              ),
            )
          : BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(
                  color: scheme.outlineVariant.withValues(
                    alpha: isDark ? 0.38 : 0.6,
                  ),
                ),
              ),
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
              accent: scheme.primary,
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
              accent: isDark ? scheme.tertiary : const Color(0xFFB86A32),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 9),
      decoration: BoxDecoration(
        color: isToday
            ? scheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TimetablePage.weekdays[weekday - 1],
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
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
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday ? scheme.tertiary : scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$courseCount',
              style: TextStyle(
                color: isToday ? scheme.onTertiary : scheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
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
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
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
          const SizedBox(height: 5),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SlotRoutePainter(
                      color: courses.isEmpty
                          ? theme.colorScheme.outlineVariant
                          : accent,
                      slots: sectionBreaks.length,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15, top: 1),
                  child: courses.isEmpty
                      // 空半区把标签贴在线路上端，不再悬在大片空白正中。
                      ? Text(
                          '沿线无课',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.58),
                            fontSize: 10,
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
                                    bottom:
                                        slotIndex == coursesBySlot.length - 1
                                        ? 0
                                        : 5,
                                  ),
                                  child: Column(
                                    children: [
                                      for (final course
                                          in coursesBySlot[slotIndex])
                                        Expanded(
                                          child: _GridCourseCard(
                                            course: course,
                                          ),
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
          ),
        ],
      ),
    );
  }
}

class _SlotRoutePainter extends CustomPainter {
  const _SlotRoutePainter({required this.color, required this.slots});

  final Color color;
  final int slots;

  @override
  void paint(Canvas canvas, Size size) {
    if (slots <= 0 || size.isEmpty) return;
    final x = 5.0;
    final routePaint = Paint()
      ..color = color.withValues(alpha: 0.34)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), routePaint);
    final stationFill = Paint()..color = color;
    final stationRing = Paint()
      ..color = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
          ? Colors.white.withValues(alpha: 0.82)
          : Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var index = 0; index < slots; index++) {
      final y = size.height * (index + 0.5) / slots;
      canvas.drawCircle(Offset(x, y), 3.4, stationFill);
      canvas.drawCircle(Offset(x, y), 4.8, stationRing);
    }
  }

  @override
  bool shouldRepaint(covariant _SlotRoutePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.slots != slots;
}

class _GridCourseCard extends StatelessWidget {
  const _GridCourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final color = courseColorFor(course.colorKey);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = const CourseTimeService().resolve(course);
    final sectionLabel = course.startSection == course.endSection
        ? '${course.startSection}节'
        : '${course.startSection}-${course.endSection}节';

    return LayoutBuilder(
      builder: (context, constraints) {
        final dense = constraints.maxHeight < 70;
        final cardRadius = BorderRadius.only(
          topLeft: const Radius.circular(3),
          bottomLeft: const Radius.circular(3),
          topRight: Radius.circular(dense ? 10 : 16),
          bottomRight: Radius.circular(dense ? 10 : 16),
        );
        final cardBase = isDark ? scheme.surfaceContainerHigh : scheme.surface;
        return Container(
          key: ValueKey('week-course-card-${course.id}'),
          decoration: BoxDecoration(
            borderRadius: cardRadius,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: cardRadius,
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: courseSurfaceTint(color, cardBase, isDark: isDark),
                ),
                borderRadius: cardRadius,
              ),
              child: InkWell(
                onTap: () => context.push('/course/${course.id}'),
                borderRadius: cardRadius,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: dense ? 7 : 9,
                          vertical: dense ? 5 : 7,
                        ),
                        child: constraints.maxHeight <= 52
                            ? FittedBox(
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.scaleDown,
                                child: _GridCourseTinyContent(
                                  course: course,
                                  sectionLabel: sectionLabel,
                                  timeLabel: time?.label,
                                  accent: color,
                                ),
                              )
                            : _GridCourseContent(
                                course: course,
                                sectionLabel: sectionLabel,
                                timeLabel: time?.label,
                                dense: dense,
                                accent: color,
                              ),
                      ),
                    ),
                  ],
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
    required this.accent,
  });

  final Course course;
  final String sectionLabel;
  final String? timeLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasMetadata =
        course.classroom.isNotEmpty || course.teacher.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.name,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 8,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 1),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: ValueKey('week-course-section-${course.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: courseBadgeTint(accent),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                sectionLabel,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 6,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (timeLabel != null) ...[
              const SizedBox(width: 3),
              Text(
                timeLabel!,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 6,
                  height: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        if (hasMetadata) ...[
          const SizedBox(height: 1),
          DefaultTextStyle(
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 6,
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
    required this.accent,
  });

  final Course course;
  final String sectionLabel;
  final String? timeLabel;
  final bool dense;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                color: courseBadgeTint(accent),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                sectionLabel,
                style: TextStyle(
                  color: scheme.onSurface,
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
                    color: scheme.onSurfaceVariant,
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
            color: scheme.onSurface,
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
              color: scheme.onSurfaceVariant,
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
