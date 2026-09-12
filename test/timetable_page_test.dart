import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/app.dart';
import 'package:ncpu_timetable/core/database/app_database.dart';
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
    expect(find.textContaining('本周 2 条安排'), findsOneWidget);

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
}
