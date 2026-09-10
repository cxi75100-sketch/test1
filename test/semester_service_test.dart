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
}
