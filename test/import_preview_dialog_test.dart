import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/features/import/services/import_diff.dart';
import 'package:ncpu_timetable/features/import/widgets/import_preview_dialog.dart';
import 'package:ncpu_timetable/models/course.dart';

Course _course(
  String id, {
  String name = '工程力学',
  String teacher = '张三',
  String classroom = 'A101',
}) => Course(
  id: id,
  name: name,
  teacher: teacher,
  classroom: classroom,
  weekday: 1,
  startSection: 3,
  endSection: 4,
  weeks: const [1, 2, 3],
  semesterId: 's1',
  colorKey: 0,
  source: CourseSource.ncpu,
);

Future<void> _pumpDialog(
  WidgetTester tester, {
  required List<Course> courses,
  ImportDiff? diff,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ImportPreviewDialog(
          schoolName: '南昌工学院',
          courses: courses,
          diff: diff,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('没有可比对的旧数据时不显示比较区块', (tester) async {
    await _pumpDialog(tester, courses: [_course('a')]);

    expect(find.text('相对上次导入'), findsNothing);
    expect(find.textContaining('与上次导入一致'), findsNothing);
  });

  testWidgets('差异为空时明示“与上次导入一致”，而不是隐藏区块', (tester) async {
    await _pumpDialog(
      tester,
      courses: [_course('a')],
      diff: const ImportDiff(added: [], removed: []),
    );

    expect(find.text('相对上次导入'), findsOneWidget);
    expect(find.textContaining('与上次导入一致'), findsOneWidget);
  });

  testWidgets('同时显示新增、移除与修改三类数量', (tester) async {
    await _pumpDialog(
      tester,
      courses: [
        _course('a'),
        _course('c', name: '线性代数A'),
      ],
      diff: ImportDiff(
        added: [_course('c', name: '线性代数A')],
        removed: [_course('b', name: '工程材料')],
        changed: [
          CourseChange(
            previous: _course('a', teacher: '张三', classroom: ''),
            current: _course('a', teacher: '李四', classroom: 'B202'),
            fields: const [
              CourseFieldChange(label: '教师', oldValue: '张三', newValue: '李四'),
              CourseFieldChange(label: '教室', oldValue: '', newValue: 'B202'),
            ],
          ),
        ],
      ),
    );

    expect(find.text('新增 1 条 · 移除 1 条 · 修改 1 条'), findsOneWidget);
    expect(find.text('将被移除：'), findsOneWidget);
    expect(find.textContaining('工程材料'), findsOneWidget);
    expect(find.text('本次修改：'), findsOneWidget);
    expect(find.textContaining('与上次导入一致'), findsNothing);
  });

  testWidgets('修改项展示“旧值 → 新值”，空值用可读占位符', (tester) async {
    await _pumpDialog(
      tester,
      courses: [_course('a')],
      diff: ImportDiff(
        added: const [],
        removed: const [],
        changed: [
          CourseChange(
            previous: _course('a', teacher: '张三'),
            current: _course('a', teacher: '李四'),
            fields: const [
              CourseFieldChange(label: '教师', oldValue: '张三', newValue: '李四'),
              CourseFieldChange(label: '教室', oldValue: '', newValue: 'B202'),
            ],
          ),
        ],
      ),
    );

    expect(find.text('教师：张三 → 李四'), findsOneWidget);
    expect(find.text('教室：（未填） → B202'), findsOneWidget);
  });

  testWidgets('只有修改时也显示三类计数，不显示“一致”', (tester) async {
    await _pumpDialog(
      tester,
      courses: [_course('a')],
      diff: ImportDiff(
        added: const [],
        removed: const [],
        changed: [
          CourseChange(
            previous: _course('a', teacher: '张三'),
            current: _course('a', teacher: '李四'),
            fields: const [
              CourseFieldChange(label: '教师', oldValue: '张三', newValue: '李四'),
            ],
          ),
        ],
      ),
    );

    expect(find.text('新增 0 条 · 移除 0 条 · 修改 1 条'), findsOneWidget);
    expect(find.textContaining('与上次导入一致'), findsNothing);
  });

  testWidgets('27 条修改在手机视口不溢出且可滚动到最后一条', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final current = [
      for (var index = 0; index < 27; index++)
        _course('course-$index', name: '课程 $index', teacher: '新教师 $index'),
    ];
    final changed = [
      for (var index = 0; index < 27; index++)
        CourseChange(
          previous: _course(
            'course-$index',
            name: '课程 $index',
            teacher: '旧教师 $index',
          ),
          current: current[index],
          fields: [
            CourseFieldChange(
              label: '教师',
              oldValue: '旧教师 $index',
              newValue: '新教师 $index',
            ),
          ],
        ),
    ];

    await _pumpDialog(
      tester,
      courses: current,
      diff: ImportDiff(added: const [], removed: const [], changed: changed),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('确认导入').hitTestable(), findsOneWidget);

    final lastChange = find.text('教师：旧教师 26 → 新教师 26');
    await tester.ensureVisible(lastChange);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(lastChange.hitTestable(), findsOneWidget);
    expect(find.text('确认导入').hitTestable(), findsOneWidget);

    final bottomHint = find.text('提示：周次要显示正确，请在「设置 → 学期设置」里填好开学第一周的周一。');
    await tester.ensureVisible(bottomHint);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(bottomHint.hitTestable(), findsOneWidget);
    expect(find.text('确认导入').hitTestable(), findsOneWidget);
  });
}
