import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/features/import/services/import_diff.dart';
import 'package:ncpu_timetable/models/course.dart';

Course _imported(
  String id, {
  String name = '工程力学',
  String teacher = '张三',
  String classroom = 'A101',
  int weekday = 1,
  int startSection = 3,
  int endSection = 4,
  List<int> weeks = const [1, 2, 3],
  String? startTime,
  String? endTime,
  String note = '',
  CourseSource source = CourseSource.ncpu,
}) => Course(
  id: id,
  name: name,
  teacher: teacher,
  classroom: classroom,
  weekday: weekday,
  startSection: startSection,
  endSection: endSection,
  weeks: weeks,
  startTime: startTime,
  endTime: endTime,
  note: note,
  semesterId: 's1',
  colorKey: 0,
  source: source,
);

void main() {
  test('首次导入时全部算作新增', () {
    final diff = diffImportedCourses(
      previous: const [],
      next: [_imported('a'), _imported('b')],
    );

    expect(diff.added, hasLength(2));
    expect(diff.removed, isEmpty);
    expect(diff.changed, isEmpty);
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
    expect(diff.changed, isEmpty);
  });

  test('不同对象、不同周次数组实例但内容相同，仍不算差异（按内容比较）', () {
    final diff = diffImportedCourses(
      previous: [
        _imported('a', weeks: [1, 2, 3]),
      ],
      next: [
        _imported('a', weeks: [1, 2, 3]),
      ],
    );

    expect(diff.isEmpty, isTrue);
  });

  test('新增与移除分别归类，未变的课程不进入任一列表', () {
    final diff = diffImportedCourses(
      previous: [_imported('a'), _imported('b')],
      next: [_imported('a'), _imported('c')],
    );

    expect(diff.added.map((course) => course.id), ['c']);
    expect(diff.removed.map((course) => course.id), ['b']);
    expect(diff.changed, isEmpty);
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
    final manual = _imported('manual-1', source: CourseSource.manual);
    final diff = diffImportedCourses(
      previous: [manual, _imported('a')],
      next: [_imported('a')],
    );

    expect(diff.isEmpty, isTrue);
  });

  test('next 中混入手动课程时不计入新增、移除或修改', () {
    final manual = _imported(
      'manual-1',
      name: '体育',
      source: CourseSource.manual,
    );
    final diff = diffImportedCourses(
      previous: [_imported('a')],
      next: [_imported('a'), manual],
    );

    expect(diff.isEmpty, isTrue);
    expect(diff.added, isEmpty);
    expect(diff.removed, isEmpty);
    expect(diff.changed, isEmpty);
  });

  test('next 中手动课程详情变化也不计入修改', () {
    final diff = diffImportedCourses(
      previous: [
        _imported('manual-1', teacher: '张三', source: CourseSource.manual),
      ],
      next: [_imported('manual-1', teacher: '李四', source: CourseSource.manual)],
    );

    expect(diff.changed, isEmpty);
    expect(diff.isEmpty, isTrue);
  });

  group('同 id 详情变化', () {
    test('改课程名、教师、教室、备注进入 changed，并同时保留新旧课程', () {
      final previous = _imported(
        'a',
        name: '工程力学',
        teacher: '张三',
        classroom: 'A101',
        note: '',
      );
      final current = _imported(
        'a',
        name: '工程力学（重修）',
        teacher: '李四',
        classroom: 'B202',
        note: '单周上课',
      );

      final diff = diffImportedCourses(previous: [previous], next: [current]);

      expect(diff.added, isEmpty);
      expect(diff.removed, isEmpty);
      expect(diff.changed, hasLength(1));
      expect(diff.isEmpty, isFalse);

      final change = diff.changed.single;
      expect(change.previous, same(previous));
      expect(change.current, same(current));
      expect(
        change.fields.map((field) => field.label),
        containsAll(['课程名', '教师', '教室', '备注']),
      );

      final teacher = change.fields.firstWhere((field) => field.label == '教师');
      expect(teacher.oldValue, '张三');
      expect(teacher.newValue, '李四');
    });

    test('改星期、节次、周次或明确起止时间进入 changed', () {
      final diff = diffImportedCourses(
        previous: [
          _imported(
            'a',
            weekday: 1,
            startSection: 3,
            endSection: 4,
            weeks: [1, 2, 3],
            startTime: '10:15',
            endTime: '11:45',
          ),
        ],
        next: [
          _imported(
            'a',
            weekday: 3,
            startSection: 5,
            endSection: 6,
            weeks: [1, 2, 3, 4],
            startTime: '14:00',
            endTime: '15:30',
          ),
        ],
      );

      expect(diff.changed, hasLength(1));
      expect(
        diff.changed.single.fields.map((field) => field.label),
        containsAll(['星期', '节次', '周次', '时间']),
      );
    });

    test('仅单字段变化时只报告该字段', () {
      final diff = diffImportedCourses(
        previous: [_imported('a', teacher: '张三')],
        next: [_imported('a', teacher: '李四')],
      );

      expect(diff.changed.single.fields, hasLength(1));
      expect(diff.changed.single.fields.single.label, '教师');
      expect(diff.changed.single.fields.single.oldValue, '张三');
      expect(diff.changed.single.fields.single.newValue, '李四');
    });

    test('未变化的同 id 课程不进入任何列表', () {
      final diff = diffImportedCourses(
        previous: [_imported('a'), _imported('b')],
        next: [_imported('a'), _imported('b')],
      );

      expect(diff.added, isEmpty);
      expect(diff.removed, isEmpty);
      expect(diff.changed, isEmpty);
    });
  });
}
