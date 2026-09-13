import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/app.dart';
import 'package:ncpu_timetable/core/database/app_database.dart';
import 'package:ncpu_timetable/core/theme/course_colors.dart';
import 'package:ncpu_timetable/features/timetable/providers/timetable_providers.dart';
import 'package:ncpu_timetable/models/course.dart';
import 'package:ncpu_timetable/models/semester.dart';

/// 本周一。用它推学期日期，测试就不依赖运行日期。
DateTime _thisMonday() {
  final now = DateTime.now();
  return DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
}

/// 用一个指定开学日的学期启动 App。
///
/// 已有学期时 `ensureDefaults` 不会再补默认学期，因此它就是唯一的活动学期。
///
/// 视口按真机设置（1272x2800 @ 560dpi ≈ 363x800 逻辑像素）。测试宽度比
/// 默认的 800 窄得多，提示条若有排版溢出会在这里直接失败，而不必改真机数据。
Future<AppDatabase> _pumpAppWithSemester(
  WidgetTester tester,
  DateTime firstWeekMonday,
) async {
  tester.view.physicalSize = const Size(1272, 2800);
  tester.view.devicePixelRatio = 3.5;
  addTearDown(tester.view.reset);

  final database = AppDatabase(executor: NativeDatabase.memory());
  await database.upsertSemester(
    Semester(
      id: 'the-semester',
      name: '测试学期',
      firstWeekMonday: firstWeekMonday,
      totalWeeks: 20,
    ),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const TimetableApp(),
    ),
  );
  await tester.pumpAndSettle();
  return database;
}

/// 必须在测试体内收尾：pending timer 的检查发生在测试体返回时，
/// 放进 `addTearDown` 就太晚了。
Future<void> _disposeApp(WidgetTester tester, AppDatabase database) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
  await database.close();
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  testWidgets('学期已结束时提示更新学期设置', (tester) async {
    // 30 周前开学、只配 20 周，今天必然在学期结束之后。
    final database = await _pumpAppWithSemester(
      tester,
      _thisMonday().subtract(const Duration(days: 30 * 7)),
    );

    expect(find.textContaining('已超出本学期'), findsOneWidget);
    expect(find.textContaining('点此更新学期设置'), findsOneWidget);

    await _disposeApp(tester, database);
  });

  testWidgets('开学日期在未来时提示周次按第 1 周显示', (tester) async {
    final database = await _pumpAppWithSemester(
      tester,
      _thisMonday().add(const Duration(days: 7)),
    );

    expect(find.textContaining('早于学期开始日'), findsOneWidget);

    await _disposeApp(tester, database);
  });

  testWidgets('学期日期在范围内时不显示提示', (tester) async {
    final database = await _pumpAppWithSemester(tester, _thisMonday());

    expect(find.textContaining('点此更新学期设置'), findsNothing);

    await _disposeApp(tester, database);
  });

  testWidgets('今日无课时提供整周、新增与导入快捷入口', (tester) async {
    final database = await _pumpAppWithSemester(tester, _thisMonday());

    expect(find.byKey(const ValueKey('empty-quick-actions')), findsOneWidget);
    expect(find.text('查看整周'), findsOneWidget);
    expect(find.text('新增课程'), findsOneWidget);
    expect(find.text('教务导入'), findsOneWidget);

    await tester.tap(find.text('查看整周'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('today-schedule')), findsNothing);
    expect(find.text('本周暂无课程'), findsOneWidget);

    await _disposeApp(tester, database);
  });

  testWidgets('今日与整周栏目相互独立且今日只显示当天课程', (tester) async {
    final database = await _pumpAppWithSemester(tester, _thisMonday());
    final today = DateTime.now().weekday;
    final anotherDay = today == 7 ? 1 : today + 1;
    await database.upsertCourse(
      Course(
        id: 'today-course',
        name: '当天课程',
        weekday: today,
        startSection: 1,
        endSection: 2,
        weeks: const [1],
        semesterId: 'the-semester',
        colorKey: 1,
      ),
    );
    await database.upsertCourse(
      Course(
        id: 'another-course',
        name: '其他日期课程',
        weekday: anotherDay,
        startSection: 3,
        endSection: 4,
        weeks: const [1],
        semesterId: 'the-semester',
        colorKey: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('today-schedule')), findsOneWidget);
    expect(find.text('今日课程'), findsOneWidget);
    expect(find.text('当天课程'), findsOneWidget);
    expect(find.text('其他日期课程'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('week-view-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('today-schedule')), findsNothing);
    expect(find.text('当天课程'), findsOneWidget);
    expect(find.text('其他日期课程'), findsOneWidget);
    expect(find.textContaining('2 门课程'), findsOneWidget);
    expect(find.byKey(const ValueKey('week-route-strip')), findsOneWidget);
    expect(
      find.byKey(ValueKey('week-route-day-$today')),
      findsOneWidget,
      reason: '整周路线图必须包含今天并可直接定位',
    );

    final todayColumn = find.byKey(ValueKey('week-day-column-$today'));
    expect(
      tester.getTopLeft(todayColumn).dx,
      closeTo(16, 1),
      reason: '进入整周时，当天日列应直接对齐到视口左侧，无需先手动横滑',
    );
    expect(
      tester.getSize(todayColumn).width,
      greaterThan(
        tester.view.physicalSize.width / tester.view.devicePixelRatio * 0.4,
      ),
      reason: '真机窄屏应完整显示两天，而不是退化成单日详情',
    );
    expect(
      tester.getSize(todayColumn).width,
      lessThan(
        tester.view.physicalSize.width / tester.view.devicePixelRatio * 0.55,
      ),
    );

    await _disposeApp(tester, database);
  });

  testWidgets('整周满课一天一列且半区内无需上下滚动', (tester) async {
    final database = await _pumpAppWithSemester(tester, _thisMonday());
    for (final course in [
      const Course(
        id: 'morning-course',
        name: '上午课程',
        weekday: 1,
        startSection: 1,
        endSection: 2,
        weeks: [1],
        semesterId: 'the-semester',
        colorKey: 1,
      ),
      const Course(
        id: 'afternoon-course',
        name: '下午课程',
        weekday: 1,
        startSection: 5,
        endSection: 6,
        weeks: [1],
        semesterId: 'the-semester',
        colorKey: 2,
      ),
      const Course(
        id: 'morning-course-2',
        name: '上午课程二',
        weekday: 1,
        startSection: 3,
        endSection: 4,
        weeks: [1],
        semesterId: 'the-semester',
        colorKey: 4,
      ),
      const Course(
        id: 'afternoon-course-2',
        name: '下午课程二',
        weekday: 1,
        startSection: 7,
        endSection: 8,
        weeks: [1],
        semesterId: 'the-semester',
        colorKey: 5,
      ),
      const Course(
        id: 'evening-course',
        name: '晚上课程',
        weekday: 1,
        startSection: 9,
        endSection: 10,
        weeks: [1],
        semesterId: 'the-semester',
        colorKey: 3,
      ),
    ]) {
      await database.upsertCourse(course);
    }
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('week-view-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('week-board-scroll')), findsOneWidget);
    expect(find.byKey(const ValueKey('week-day-column-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('week-day-column-7')), findsOneWidget);
    final morningHalf = find.byKey(const ValueKey('day-1-morning'));
    final laterHalf = find.byKey(const ValueKey('day-1-later'));
    expect(morningHalf, findsOneWidget);
    expect(laterHalf, findsOneWidget);
    expect(
      tester.getSize(morningHalf).height,
      closeTo(tester.getSize(laterHalf).height, 1),
    );
    expect(
      find.descendant(of: morningHalf, matching: find.text('上午课程')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: morningHalf, matching: find.text('上午课程二')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: laterHalf, matching: find.text('下午课程')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: laterHalf, matching: find.text('下午课程二')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: laterHalf, matching: find.text('晚上课程')),
      findsOneWidget,
    );
    final courseCardFinder = find.byKey(
      const ValueKey('week-course-card-morning-course'),
    );
    final courseCard = tester.widget<Container>(courseCardFinder);
    final cardDecoration = courseCard.decoration! as BoxDecoration;
    final cardRadius = cardDecoration.borderRadius! as BorderRadius;
    expect(cardRadius.topLeft, const Radius.circular(3));
    expect(cardRadius.topRight.x, greaterThan(cardRadius.topLeft.x));
    final cardInk = tester.widget<Ink>(
      find.descendant(of: courseCardFinder, matching: find.byType(Ink)),
    );
    final inkDecoration = cardInk.decoration! as BoxDecoration;
    expect(inkDecoration.gradient, isA<LinearGradient>());
    final sectionBadge = tester.widget<Container>(
      find.byKey(const ValueKey('week-course-section-morning-course')),
    );
    expect(
      (sectionBadge.decoration! as BoxDecoration).color,
      courseColorFor(1).withValues(alpha: 0.18),
    );
    expect(
      find.descendant(of: morningHalf, matching: find.byType(Scrollable)),
      findsNothing,
    );
    expect(
      find.descendant(of: laterHalf, matching: find.byType(Scrollable)),
      findsNothing,
    );

    final sundayBefore = tester
        .getTopLeft(find.byKey(const ValueKey('week-day-column-7')))
        .dx;
    await tester.drag(
      find.byKey(const ValueKey('week-board-scroll')),
      const Offset(-700, 0),
    );
    await tester.pumpAndSettle();
    final sundayAfter = tester
        .getTopLeft(find.byKey(const ValueKey('week-day-column-7')))
        .dx;
    expect(sundayAfter, lessThan(sundayBefore));

    await _disposeApp(tester, database);
  });

  testWidgets('夜间整周使用分层表面且选中栏目以线路强调', (tester) async {
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );
    final database = await _pumpAppWithSemester(tester, _thisMonday());
    await database.upsertCourse(
      Course(
        id: 'dark-course',
        name: '夜间主题课程',
        weekday: DateTime.now().weekday,
        startSection: 1,
        endSection: 2,
        weeks: const [1],
        semesterId: 'the-semester',
        colorKey: 1,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('week-view-button')));
    await tester.pumpAndSettle();

    final context = tester.element(
      find.byKey(const ValueKey('schedule-view-switcher')),
    );
    final scheme = Theme.of(context).colorScheme;
    final switcher = tester.widget<Container>(
      find.byKey(const ValueKey('schedule-view-switcher')),
    );
    expect(
      (switcher.decoration! as BoxDecoration).border?.bottom.color,
      scheme.outlineVariant,
    );

    final selectedMaterial = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(const ValueKey('week-view-button')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(selectedMaterial.color, Colors.transparent);

    final todayColumn = tester.widget<Container>(
      find.byKey(ValueKey('week-day-column-${DateTime.now().weekday}')),
    );
    expect(
      (todayColumn.decoration! as BoxDecoration).color,
      scheme.surface.withValues(alpha: 0.58),
    );
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      Colors.transparent,
      reason: '页面背景应从状态栏连续铺到页面底部',
    );

    await _disposeApp(tester, database);
  });

  testWidgets('今日列表卡沿用整周的课程面与节次签', (tester) async {
    final database = await _pumpAppWithSemester(tester, _thisMonday());
    await database.upsertCourse(
      Course(
        id: 'today-card',
        name: '今日卡片课程',
        weekday: DateTime.now().weekday,
        startSection: 1,
        endSection: 2,
        weeks: const [1],
        semesterId: 'the-semester',
        colorKey: 1,
        classroom: '明志楼101',
        teacher: '张老师',
      ),
    );
    await tester.pumpAndSettle();

    final cardFinder = find.byKey(
      const ValueKey('today-course-card-today-card'),
    );
    final card = tester.widget<Container>(cardFinder);
    expect(
      (card.decoration! as BoxDecoration).borderRadius,
      BorderRadius.circular(16),
      reason: '列表卡圆角应与主题 cardTheme 一致，不再各写一个值',
    );
    final scheme = Theme.of(tester.element(cardFinder)).colorScheme;
    final gradient =
        (tester
                        .widget<Ink>(
                          find.descendant(
                            of: cardFinder,
                            matching: find.byType(Ink),
                          ),
                        )
                        .decoration!
                    as BoxDecoration)
                .gradient!
            as LinearGradient;
    expect(
      gradient.colors,
      courseSurfaceTint(courseColorFor(1), scheme.surface, isDark: false),
      reason: '列表卡应与整周卡共用同一组低饱和课程面系数',
    );

    final badge = tester.widget<Container>(
      find.byKey(const ValueKey('today-course-section-today-card')),
    );
    final badgeColor = (badge.decoration! as BoxDecoration).color!;
    expect(badgeColor, courseBadgeTint(courseColorFor(1)));
    expect(badgeColor.a, lessThan(0.3), reason: '节次签是淡色标签，不应再是实心亮黄章');

    await _disposeApp(tester, database);
  });

  testWidgets('今日与整周切换按钮满足 48dp 触控目标', (tester) async {
    final database = await _pumpAppWithSemester(tester, _thisMonday());

    for (final key in ['today-view-button', 'week-view-button']) {
      expect(
        tester.getSize(find.byKey(ValueKey(key))).height,
        greaterThanOrEqualTo(48),
        reason: '$key 的触控高度不能低于 48dp',
      );
    }

    await _disposeApp(tester, database);
  });

  testWidgets('空日列只留列轨、不画整列卡片', (tester) async {
    final database = await _pumpAppWithSemester(tester, _thisMonday());
    final today = DateTime.now().weekday;
    final emptyDay = today == 1 ? 2 : 1;
    await database.upsertCourse(
      Course(
        id: 'lonely-course',
        name: '唯一的一门课',
        weekday: today,
        startSection: 1,
        endSection: 2,
        weeks: const [1],
        semesterId: 'the-semester',
        colorKey: 1,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('week-view-button')));
    await tester.pumpAndSettle();

    final columnFinder = find.byKey(ValueKey('week-day-column-$emptyDay'));
    final decoration =
        tester.widget<Container>(columnFinder).decoration! as BoxDecoration;
    expect(decoration.color, isNull, reason: '空日不应有卡片填充色');
    expect(decoration.borderRadius, isNull, reason: '空日不应有卡片外形');

    final columnRect = tester.getRect(columnFinder);
    final labelRect = tester.getRect(
      find.descendant(of: columnFinder, matching: find.text('沿线无课')).first,
    );
    expect(
      labelRect.top - columnRect.top,
      lessThan(columnRect.height * 0.35),
      reason: '「沿线无课」应贴在线路上端，而不是悬在半区正中',
    );

    await _disposeApp(tester, database);
  });

  testWidgets('详情页头卡画出十站节次线路且节次落点正确', (tester) async {
    final database = await _pumpAppWithSemester(tester, _thisMonday());
    await database.upsertCourse(
      Course(
        id: 'detail-course',
        name: '详情课程',
        weekday: DateTime.now().weekday,
        startSection: 3,
        endSection: 4,
        weeks: const [1],
        semesterId: 'the-semester',
        colorKey: 2,
        classroom: '明志楼101',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('today-course-card-detail-course')),
    );
    await tester.pumpAndSettle();

    expect(find.text('课程详情'), findsOneWidget);
    for (var section = 1; section <= 10; section++) {
      expect(
        find.byKey(ValueKey('detail-section-station-$section')),
        findsOneWidget,
        reason: '一天十节，线路应有十站',
      );
    }
    expect(
      (tester
                  .widget<Container>(
                    find.byKey(const ValueKey('detail-section-station-3')),
                  )
                  .decoration!
              as BoxDecoration)
          .color,
      courseColorFor(2),
      reason: '课程占用的节次应画成实心站点',
    );
    expect(
      (tester
                  .widget<Container>(
                    find.byKey(const ValueKey('detail-section-station-1')),
                  )
                  .decoration!
              as BoxDecoration)
          .color,
      Colors.transparent,
      reason: '课程未占用的节次只留描边站点',
    );

    await _disposeApp(tester, database);
  });
}
