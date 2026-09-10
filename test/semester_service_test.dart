import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/models/semester.dart';
import 'package:ncpu_timetable/services/semester_service.dart';

void main() {
  const service = SemesterService();
  final semester = Semester(
    id: 's1',
    name: '测试学期',
    firstWeekMonday: DateTime(2026, 9, 7),
    totalWeeks: 20,
  );

  test(
    'first week returns 1',
    () => expect(service.currentWeek(semester, DateTime(2026, 9, 7)), 1),
  );
  test(
    'second week returns 2',
    () => expect(service.currentWeek(semester, DateTime(2026, 9, 14)), 2),
  );
  test(
    'before semester returns 0',
    () => expect(service.currentWeek(semester, DateTime(2026, 9, 6)), 0),
  );
  test(
    'after semester clamps to total weeks',
    () => expect(service.currentWeek(semester, DateTime(2027, 3, 1)), 20),
  );
  test(
    'time of day does not shift week boundary',
    () =>
        expect(service.currentWeek(semester, DateTime(2026, 9, 13, 23, 59)), 1),
  );

  group('termStatus', () {
    test('开学前为 before', () {
      expect(
        service.termStatus(semester, DateTime(2026, 9, 6)),
        TermStatus.before,
      );
    });

    test('开学当天与学期最后一天都为 within', () {
      expect(
        service.termStatus(semester, DateTime(2026, 9, 7)),
        TermStatus.within,
      );
      // 2026-09-07 起 20 周，最后一个在学期内的日期是 2027-01-24。
      expect(
        service.termStatus(semester, DateTime(2027, 1, 24)),
        TermStatus.within,
      );
    });

    test('超出总周数后为 after（此时 currentWeek 已封顶，无法区分）', () {
      final date = DateTime(2027, 1, 25);
      expect(service.termStatus(semester, date), TermStatus.after);
      // 同一个日期 currentWeek 会返回 totalWeeks，看不出学期已结束。
      expect(service.currentWeek(semester, date), semester.totalWeeks);
    });
  });

  group('dateFor', () {
    test('第 1 周周一等于开学日', () {
      expect(service.dateFor(semester, 1, 1), DateTime(2026, 9, 7));
    });

    test('第 2 周周一与第 3 周周日', () {
      expect(service.dateFor(semester, 2, 1), DateTime(2026, 9, 14));
      expect(service.dateFor(semester, 3, 7), DateTime(2026, 9, 27));
    });

    test('不把周次夹到学期范围内（周次条要如实显示翻到的那一周）', () {
      expect(service.dateFor(semester, 21, 1), DateTime(2027, 1, 25));
    });
  });
}
