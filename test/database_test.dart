import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/core/database/app_database.dart';
import 'package:ncpu_timetable/models/course.dart';
import 'package:ncpu_timetable/models/semester.dart';

void main() {
  late AppDatabase database;
  final semester = Semester(
    id: 's1',
    name: '测试学期',
    firstWeekMonday: DateTime(2026, 9, 7),
    totalWeeks: 20,
  );

  setUp(() async {
    database = AppDatabase(executor: NativeDatabase.memory());
    await database.upsertSemester(semester);
  });
  tearDown(() => database.close());

  test('CRUD and teaching-week query', () async {
    final course = _course('c1', weeks: [1, 3]);
    await database.upsertCourse(course);
    expect(
      (await database.watchCourses('s1', week: 1).first).single.name,
      '高等数学',
    );
    expect(await database.watchCourses('s1', week: 2).first, isEmpty);
    await database.upsertCourse(course.copyWith(classroom: '教学楼 201'));
    expect((await database.findCourse('c1'))!.classroom, '教学楼 201');
    expect(await database.deleteCourse('c1'), 1);
    expect(await database.findCourse('c1'), isNull);
  });

  test('replace import preserves manual courses', () async {
    await database.upsertCourse(_course('manual'));
    await database.upsertCourse(
      _course('old-import', source: CourseSource.ncpu),
    );
    await database.replaceImportedCourses('s1', [
      _course('new-import', source: CourseSource.ncpu),
    ]);
    final values = await database.watchCourses('s1').first;
    expect(values.map((item) => item.id).toSet(), {'manual', 'new-import'});
  });

  test(
    'settings can be watched and updated without a schema migration',
    () async {
      expect(await database.watchSettings().first, isEmpty);

      await database.setSetting('notification_enabled', 'true');
      await database.setSetting('notification_minutes_before', '30');

      final values = await database.allSettings();
      expect(values['notification_enabled'], 'true');
      expect(values['notification_minutes_before'], '30');
    },
  );
}

Course _course(
  String id, {
  List<int> weeks = const [1],
  CourseSource source = CourseSource.manual,
}) => Course(
  id: id,
  name: '高等数学',
  weekday: 1,
  startSection: 1,
  endSection: 2,
  weeks: weeks,
  semesterId: 's1',
  colorKey: 1,
  source: source,
);
