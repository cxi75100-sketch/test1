import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/core/database/app_database.dart';
import 'package:ncpu_timetable/services/semester_service.dart';

void main() {
  test('ensureDefaults 可以重复调用（App 每次启动都会调用它）', () async {
    final database = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(database.close);

    await database.ensureDefaults();
    // 第二次启动：数据已存在，重复同步官方作息也必须保持幂等。
    await database.ensureDefaults();

    expect(await database.currentSemester(), isNotNull);
    final sectionTimes = await database.allSectionTimes();
    expect(sectionTimes, hasLength(10));
    expect(sectionTimes.first.startTime, '08:20');
    expect(sectionTimes.first.endTime, '09:00');
    expect(sectionTimes.last.startTime, '19:50');
    expect(sectionTimes.last.endTime, '20:30');
  });

  test('全新安装的默认学期起点来自校历，而不是安装当天所在周的周一', () async {
    final database = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(database.close);

    await database.ensureDefaults();
    final semester = (await database.currentSemester())!;

    expect(semester.firstWeekMonday, officialFirstWeekMonday);
    expect(semester.firstWeekMonday, DateTime(2026, 8, 31));
    expect(semester.totalWeeks, defaultTotalWeeks);
    // 2026-09-10 属于第 2 教学周；按“安装当天所在周的周一”会误判为第 1 周。
    expect(
      const SemesterService().currentWeek(semester, DateTime(2026, 9, 10)),
      2,
    );
  });
}
