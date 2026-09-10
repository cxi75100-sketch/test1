import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/features/import/services/import_diff.dart';
import 'package:ncpu_timetable/models/course.dart';

Course _imported(
  String id, {
  String name = '工程力学',
  int weekday = 1,
  int startSection = 3,
}) => Course(
  id: id,
  name: name,
  weekday: weekday,
  startSection: startSection,
  endSection: startSection + 1,
  weeks: const [1, 2, 3],
  semesterId: 's1',
  colorKey: 0,
  source: CourseSource.ncpu,
);

void main() {
  test('首次导入时全部算作新增', () {
    final diff = diffImportedCourses(previous: const [], next: [
      _imported('a'),
      _imported('b'),
    ]);

    expect(diff.added, hasLength(2));
    expect(diff.removed, isEmpty);
    expect(diff.isEmpty, isFalse);
  });

  test('两次导入内容相同时没有任何差异', () {
    final diff = diffImportedCourses(
      previous: [_imported('a'), _imported('b')],
      next: [_imported('a'), _imported('b')],
    );

    expect(diff.isEmpty, isTrue);
    expect(diff.added, isEmpty);
    expect(diff.removed, isEmpty);
  });

  test('新增与移除分别归类，未变的课程不进入任一列表', () {
    final diff = diffImportedCourses(
      previous: [_imported('a'), _imported('b')],
      next: [_imported('a'), _imported('c')],
    );

    expect(diff.added.map((course) => course.id), ['c']);
    expect(diff.removed.map((course) => course.id), ['b']);
  });

  test('只有剩余的一侧变化时另一侧为空', () {
    final onlyAdded = diffImportedCourses(
      previous: [_imported('a')],
      next: [_imported('a'), _imported('b')],
    );
    expect(onlyAdded.added.map((course) => course.id), ['b']);
    expect(onlyAdded.removed, isEmpty);

    final onlyRemoved = diffImportedCourses(
      previous: [_imported('a'), _imported('b')],
      next: [_imported('a')],
    );
    expect(onlyRemoved.added, isEmpty);
    expect(onlyRemoved.removed.map((course) => course.id), ['b']);
  });

  test('只比较教务来源：手动课程不参与差异', () {
    final manual = _imported('manual-1').copyWith(
      source: CourseSource.manual,
    );
    final diff = diffImportedCourses(
      previous: [manual, _imported('a')],
      next: [_imported('a')],
    );

    expect(diff.isEmpty, isTrue);
  });

  test('同一 id 改了课程名不算差异（id 是教学班+节次+周次指纹）', () {
    final diff = diffImportedCourses(
      previous: [_imported('a', name: '工程力学')],
      next: [_imported('a', name: '工程力学（重修）')],
    );

    expect(diff.isEmpty, isTrue);
  });
}
