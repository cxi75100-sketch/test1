import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/features/notifications/models/notification_preferences.dart';
import 'package:ncpu_timetable/features/notifications/services/notification_coordinator.dart';
import 'package:ncpu_timetable/features/notifications/services/notification_planner.dart';
import 'package:ncpu_timetable/features/notifications/services/notification_scheduler.dart';

void main() {
  late _FakeScheduler scheduler;
  late Map<String, String> settings;
  late NotificationCoordinator coordinator;

  setUp(() {
    scheduler = _FakeScheduler();
    settings = {};
    coordinator = NotificationCoordinator(
      scheduler: scheduler,
      loadPreferences: () async =>
          NotificationPreferences.fromSettings(settings),
      loadReminders: (_) async => const [],
      persistSetting: (key, value) async => settings[key] = value,
    );
  });

  test('默认关闭时取消历史排程', () async {
    await coordinator.flush();

    expect(scheduler.cancelCalls, 1);
    expect(scheduler.replaceCalls, 0);
  });

  test('通知权限被拒绝时不保存开启状态', () async {
    scheduler.permission = const NotificationPermissionResult(
      notificationsGranted: false,
      exactAlarmsGranted: false,
    );

    final result = await coordinator.setEnabled(true);

    expect(result, NotificationEnableResult.permissionDenied);
    expect(settings[notificationEnabledSettingKey], isNull);
    expect(scheduler.replaceCalls, 0);
  });

  test('授权后保存开启状态并重建排程', () async {
    final result = await coordinator.setEnabled(true);

    expect(result, NotificationEnableResult.enabled);
    expect(settings[notificationEnabledSettingKey], 'true');
    expect(scheduler.replaceCalls, 1);
  });

  test('精确闹钟未授权时保留开启并报告降级', () async {
    scheduler.permission = const NotificationPermissionResult(
      notificationsGranted: true,
      exactAlarmsGranted: false,
    );

    final result = await coordinator.setEnabled(true);

    expect(result, NotificationEnableResult.enabledInexact);
    expect(settings[notificationEnabledSettingKey], 'true');
    expect(scheduler.replaceCalls, 1);
  });

  test('系统排程失败时回滚开启状态', () async {
    scheduler.throwOnReplace = true;

    final result = await coordinator.setEnabled(true);

    expect(result, NotificationEnableResult.failed);
    expect(settings[notificationEnabledSettingKey], 'false');
  });

  test('关闭提醒会保存状态并取消排程', () async {
    settings[notificationEnabledSettingKey] = 'true';

    await coordinator.setEnabled(false);

    expect(settings[notificationEnabledSettingKey], 'false');
    expect(scheduler.cancelCalls, 1);
  });

  test('修改提前时间会保存并重建排程', () async {
    settings[notificationEnabledSettingKey] = 'true';

    await coordinator.setMinutesBefore(30);

    expect(settings[notificationMinutesSettingKey], '30');
    expect(scheduler.replaceCalls, 1);
  });
}

class _FakeScheduler implements NotificationScheduler {
  NotificationPermissionResult permission = const NotificationPermissionResult(
    notificationsGranted: true,
    exactAlarmsGranted: true,
  );
  int cancelCalls = 0;
  int replaceCalls = 0;
  bool throwOnReplace = false;

  @override
  Future<void> cancelAll() async => cancelCalls++;

  @override
  Future<NotificationPermissionResult> requestPermissions() async => permission;

  @override
  Future<void> replaceAll(List<CourseReminder> reminders) async {
    replaceCalls++;
    if (throwOnReplace) throw StateError('schedule failed');
  }
}
