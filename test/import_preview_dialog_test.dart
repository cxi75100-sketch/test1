import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/features/import/services/import_diff.dart';
import 'package:ncpu_timetable/features/import/widgets/import_preview_dialog.dart';
import 'package:ncpu_timetable/models/course.dart';

Course _course(String id, {String name = '工程力学'}) => Course(
  id: id,
  name: name,
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

  testWidgets('有新增与移除时显示条数并列出被移除的课程', (tester) async {
    await _pumpDialog(
      tester,
      courses: [_course('a'), _course('c', name: '线性代数A')],
      diff: ImportDiff(
        added: [_course('c', name: '线性代数A')],
        removed: [_course('b', name: '工程材料')],
      ),
    );

    expect(find.text('新增 1 条 · 移除 1 条'), findsOneWidget);
    expect(find.text('将被移除：'), findsOneWidget);
    expect(find.textContaining('工程材料'), findsOneWidget);
  });
}
