import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/core/database/app_database.dart';
import 'package:ncpu_timetable/features/notifications/models/notification_preferences.dart';
import 'package:ncpu_timetable/features/notifications/providers/notification_providers.dart';
import 'package:ncpu_timetable/features/notifications/services/notification_coordinator.dart';
import 'package:ncpu_timetable/features/notifications/services/notification_planner.dart';
import 'package:ncpu_timetable/features/notifications/services/notification_scheduler.dart';
import 'package:ncpu_timetable/features/settings/pages/settings_page.dart';
import 'package:ncpu_timetable/features/timetable/providers/timetable_providers.dart';

void main() {
  late AppDatabase database;
  late _FakeScheduler scheduler;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    scheduler = _FakeScheduler();
  });

  tearDown(() => database.close());

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final coordinator = NotificationCoordinator(
      scheduler: scheduler,
      loadPreferences: () async =>
          NotificationPreferences.fromSettings(await database.allSettings()),
      loadReminders: (_) async => const [],
      persistSetting: database.setSetting,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          notificationCoordinatorProvider.overrideWithValue(coordinator),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> disposeSettings(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets('提醒默认关闭且展示 15 分钟默认值', (tester) async {
    await pumpSettings(tester);

    expect(find.text('已关闭 · 默认提前 15 分钟'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('提醒时间'), findsNothing);
    await disposeSettings(tester);
  });

  testWidgets('用户开启时申请权限并展示降级提示', (tester) async {
    scheduler.permission = const NotificationPermissionResult(
      notificationsGranted: true,
      exactAlarmsGranted: false,
    );
    await pumpSettings(tester);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.textContaining('系统可能延迟提醒').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(scheduler.permissionCalls, 1);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text('提醒时间'), findsOneWidget);
    expect(find.textContaining('系统可能延迟提醒'), findsOneWidget);
    await disposeSettings(tester);
  });

  testWidgets('可将提前时间改为 30 分钟', (tester) async {
    await database.setSetting(notificationEnabledSettingKey, 'true');
    await pumpSettings(tester);

    await tester.ensureVisible(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 分钟').last);
    await tester.pumpAndSettle();

    final settings = await database.allSettings();
    expect(settings[notificationMinutesSettingKey], '30');
    expect(find.text('已开启 · 提前 30 分钟'), findsOneWidget);
    await disposeSettings(tester);
  });
}

class _FakeScheduler implements NotificationScheduler {
  NotificationPermissionResult permission = const NotificationPermissionResult(
    notificationsGranted: true,
    exactAlarmsGranted: true,
  );
  int permissionCalls = 0;

  @override
  Future<void> cancelAll() async {}

  @override
  Future<NotificationPermissionResult> requestPermissions() async {
    permissionCalls++;
    return permission;
  }

  @override
  Future<void> replaceAll(List<CourseReminder> reminders) async {}
}
