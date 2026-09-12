import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/core/database/app_database.dart';
import 'package:ncpu_timetable/features/notifications/models/notification_preferences.dart';
import 'package:ncpu_timetable/features/notifications/providers/notification_providers.dart';
import 'package:ncpu_timetable/features/notifications/services/notification_planner.dart';
import 'package:ncpu_timetable/features/notifications/services/notification_scheduler.dart';
import 'package:ncpu_timetable/features/timetable/providers/timetable_providers.dart';
import 'package:ncpu_timetable/models/course.dart';
import 'package:ncpu_timetable/models/semester.dart';

void main() {
  late AppDatabase database;
  late _FakeScheduler scheduler;
  late ProviderContainer container;

  setUp(() async {
    database = AppDatabase(executor: NativeDatabase.memory());
    scheduler = _FakeScheduler();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        notificationSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
    await database.upsertSemester(
      Semester(
        id: 'future',
        name: '未来学期',
        firstWeekMonday: DateTime(2030, 1, 7),
        totalWeeks: 20,
      ),
    );
    await database.setSetting(notificationEnabledSettingKey, 'true');
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  Future<void> startSync() async {
    final subscription = container.listen(
      notificationCoordinatorProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(databaseReadyProvider.future);
    await container.read(notificationPreferencesProvider.future);
    await pumpEventQueue();
  }

  test('开启后启动会排程，课程变化会重建未来提醒', () async {
    await startSync();
    expect(scheduler.replaceCalls, greaterThan(0));
    final before = scheduler.replaceCalls;

    await database.upsertCourse(
      const Course(
        id: 'future-course',
        name: '高等数学',
        classroom: 'A101',
        weekday: 1,
        startSection: 1,
        endSection: 2,
        weeks: [1],
        semesterId: 'future',
        colorKey: 1,
      ),
    );
    await pumpEventQueue();

    expect(scheduler.replaceCalls, greaterThan(before));
    expect(scheduler.lastReminders, hasLength(1));
    expect(scheduler.lastReminders.single.course.id, 'future-course');
  });
}

class _FakeScheduler implements NotificationScheduler {
  int replaceCalls = 0;
  List<CourseReminder> lastReminders = const [];

  @override
  Future<void> cancelAll() async {}

  @override
  Future<NotificationPermissionResult> requestPermissions() async =>
      const NotificationPermissionResult(
        notificationsGranted: true,
        exactAlarmsGranted: true,
      );

  @override
  Future<void> replaceAll(List<CourseReminder> reminders) async {
    replaceCalls++;
    lastReminders = reminders;
  }
}
