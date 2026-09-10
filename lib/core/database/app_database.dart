import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/course.dart' as domain;
import '../../models/section_time.dart' as domain;
import '../../models/semester.dart' as domain;
import '../../services/course_time_service.dart';
import '../../services/semester_service.dart';

part 'app_database.g.dart';

@DataClassName('SemesterRow')
class Semesters extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get firstWeekMonday => dateTime()();
  IntColumn get totalWeeks => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CourseRow')
class CourseEntries extends Table {
  @override
  String get tableName => 'courses';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get teacher => text().withDefault(const Constant(''))();
  TextColumn get classroom => text().withDefault(const Constant(''))();
  IntColumn get weekday => integer()();
  IntColumn get startSection => integer()();
  IntColumn get endSection => integer()();
  TextColumn get startTime => text().nullable()();
  TextColumn get endTime => text().nullable()();
  TextColumn get weeksJson => text()();
  TextColumn get semesterId =>
      text().references(Semesters, #id, onDelete: KeyAction.cascade)();
  IntColumn get colorKey => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant('manual'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SectionTimeRow')
class SectionTimeEntries extends Table {
  @override
  String get tableName => 'section_times';

  IntColumn get section => integer()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();

  @override
  Set<Column<Object>> get primaryKey => {section};
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [Semesters, CourseEntries, SectionTimeEntries, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  /// 保证存在默认学期与默认节次时间。
  ///
  /// 每次 App 启动都会调用，因此必须可重复且幂等：
  /// 查询必须带 `limit(1)`——`getSingleOrNull()` 在结果多于一行时会抛
  /// `Bad state: Too many elements`（节次表有 10 行，第二次启动即触发）。
  Future<void> ensureDefaults() async {
    final existingSemester = await (select(
      semesters,
    )..limit(1)).getSingleOrNull();
    if (existingSemester == null) {
      await upsertSemester(
        domain.Semester(
          id: 'default-semester',
          name: '当前学期',
          firstWeekMonday: officialFirstWeekMonday,
          totalWeeks: 20,
        ),
      );
    }
    // 作息由学校教学周历确定，启动时幂等同步，修正旧版本内置的过时时间。
    await batch(
      (batch) => batch.insertAll(
        sectionTimeEntries,
        officialSectionTimes.map(
          (v) => SectionTimeEntriesCompanion.insert(
            section: Value(v.section),
            startTime: v.startTime,
            endTime: v.endTime,
          ),
        ),
        mode: InsertMode.insertOrReplace,
      ),
    );
  }

  Stream<List<domain.Semester>> watchSemesters() =>
      (select(semesters)
            ..orderBy([(row) => OrderingTerm.desc(row.firstWeekMonday)]))
          .watch()
          .map((rows) => rows.map(_semesterFromRow).toList());

  Future<domain.Semester?> firstSemester() async {
    final row =
        await (select(semesters)
              ..orderBy([(row) => OrderingTerm.desc(row.firstWeekMonday)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _semesterFromRow(row);
  }

  Future<void> upsertSemester(domain.Semester semester) =>
      into(semesters).insertOnConflictUpdate(
        SemestersCompanion.insert(
          id: semester.id,
          name: semester.name,
          firstWeekMonday: semester.firstWeekMonday,
          totalWeeks: semester.totalWeeks,
        ),
      );

  Stream<List<domain.Course>> watchCourses(String semesterId, {int? week}) {
    final query = select(courseEntries)
      ..where((row) => row.semesterId.equals(semesterId))
      ..orderBy([
        (row) => OrderingTerm.asc(row.weekday),
        (row) => OrderingTerm.asc(row.startSection),
      ]);
    return query.watch().map((rows) {
      final courses = rows.map(_courseFromRow);
      return (week == null
              ? courses
              : courses.where((course) => course.weeks.contains(week)))
          .toList();
    });
  }

  Future<domain.Course?> findCourse(String id) async {
    final row = await (select(
      courseEntries,
    )..where((entry) => entry.id.equals(id))).getSingleOrNull();
    return row == null ? null : _courseFromRow(row);
  }

  Future<List<domain.SectionTime>> allSectionTimes() async {
    final rows = await (select(
      sectionTimeEntries,
    )..orderBy([(row) => OrderingTerm.asc(row.section)])).get();
    return rows.map(_sectionTimeFromRow).toList();
  }

  Stream<List<domain.SectionTime>> watchSectionTimes() =>
      (select(sectionTimeEntries)
            ..orderBy([(row) => OrderingTerm.asc(row.section)]))
          .watch()
          .map((rows) => rows.map(_sectionTimeFromRow).toList());

  Future<void> upsertCourse(domain.Course course) =>
      into(courseEntries).insertOnConflictUpdate(
        CourseEntriesCompanion.insert(
          id: course.id,
          name: course.name,
          teacher: Value(course.teacher),
          classroom: Value(course.classroom),
          weekday: course.weekday,
          startSection: course.startSection,
          endSection: course.endSection,
          startTime: Value(course.startTime),
          endTime: Value(course.endTime),
          weeksJson: jsonEncode(course.weeks),
          semesterId: course.semesterId,
          colorKey: course.colorKey,
          note: Value(course.note),
          source: Value(course.source.name),
        ),
      );

  Future<int> deleteCourse(String id) =>
      (delete(courseEntries)..where((row) => row.id.equals(id))).go();

  Future<int> clearSemester(String semesterId) => (delete(
    courseEntries,
  )..where((row) => row.semesterId.equals(semesterId))).go();

  Future<void> replaceImportedCourses(
    String semesterId,
    List<domain.Course> courses,
  ) => transaction(() async {
    await (delete(courseEntries)..where(
          (row) =>
              row.semesterId.equals(semesterId) &
              row.source.equals(domain.CourseSource.ncpu.name),
        ))
        .go();
    await batch(
      (batch) => batch.insertAll(courseEntries, courses.map(_courseCompanion)),
    );
  });

  domain.Semester _semesterFromRow(SemesterRow row) => domain.Semester(
    id: row.id,
    name: row.name,
    firstWeekMonday: row.firstWeekMonday,
    totalWeeks: row.totalWeeks,
  );

  domain.SectionTime _sectionTimeFromRow(SectionTimeRow row) =>
      domain.SectionTime(
        section: row.section,
        startTime: row.startTime,
        endTime: row.endTime,
      );

  domain.Course _courseFromRow(CourseRow row) => domain.Course(
    id: row.id,
    name: row.name,
    teacher: row.teacher,
    classroom: row.classroom,
    weekday: row.weekday,
    startSection: row.startSection,
    endSection: row.endSection,
    startTime: row.startTime,
    endTime: row.endTime,
    weeks: (jsonDecode(row.weeksJson) as List<dynamic>).cast<int>(),
    semesterId: row.semesterId,
    colorKey: row.colorKey,
    note: row.note,
    source: domain.CourseSource.values.byName(row.source),
  );

  CourseEntriesCompanion _courseCompanion(domain.Course course) =>
      CourseEntriesCompanion.insert(
        id: course.id,
        name: course.name,
        teacher: Value(course.teacher),
        classroom: Value(course.classroom),
        weekday: course.weekday,
        startSection: course.startSection,
        endSection: course.endSection,
        startTime: Value(course.startTime),
        endTime: Value(course.endTime),
        weeksJson: jsonEncode(course.weeks),
        semesterId: course.semesterId,
        colorKey: course.colorKey,
        note: Value(course.note),
        source: Value(course.source.name),
      );
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File(p.join(directory.path, 'ncpu_timetable.sqlite'));
  return NativeDatabase.createInBackground(file);
});
