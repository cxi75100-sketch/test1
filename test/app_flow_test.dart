import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/app.dart';
import 'package:ncpu_timetable/core/database/app_database.dart';
import 'package:ncpu_timetable/features/timetable/providers/timetable_providers.dart';
import 'package:ncpu_timetable/models/course.dart';
import 'package:ncpu_timetable/services/semester_service.dart';

void main() {
  testWidgets('user can add a manual course and see it in timetable', (
    tester,
  ) async {
    final database = AppDatabase(executor: NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const TimetableApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('今天没有课程'), findsOneWidget);
    await tester.tap(find.byTooltip('新增课程'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, '课程名 *'), '线性代数');
    await tester.tap(find.text('保存课程'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('week-view-button')));
    await tester.pumpAndSettle();
    expect(find.text('线性代数'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('week agenda includes weekend courses and useful metadata', (
    tester,
  ) async {
    final database = AppDatabase(executor: NativeDatabase.memory());
    await database.ensureDefaults();
    // 默认学期起点由校历决定，因此“当前周”随运行日期变化；
    // 这里按与界面相同的规则取当前周，避免测试依赖具体运行日期。
    final semester = (await database.currentSemester())!;
    final currentWeek = const SemesterService().currentWeek(
      semester,
      DateTime.now(),
    );
    await database.upsertCourse(
      Course(
        id: 'weekend-course',
        name: '创新实践',
        teacher: '指导教师',
        classroom: '工程训练中心',
        weekday: 7,
        startSection: 9,
        endSection: 10,
        weeks: [currentWeek],
        semesterId: 'default-semester',
        colorKey: 3,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const TimetableApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('week-view-button')));
    await tester.pumpAndSettle();
    expect(find.text('周日'), findsOneWidget);
    expect(find.text('创新实践'), findsOneWidget);
    expect(find.text('工程训练中心'), findsOneWidget);
    expect(find.text('指导教师'), findsOneWidget);
    expect(find.text('9-10节'), findsOneWidget);
    expect(find.text('19:00-20:30'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
    await tester.pump(const Duration(milliseconds: 1));
  });
}
