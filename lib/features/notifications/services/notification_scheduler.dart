import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import 'notification_planner.dart';

class NotificationPermissionResult {
  const NotificationPermissionResult({
    required this.notificationsGranted,
    required this.exactAlarmsGranted,
  });

  final bool notificationsGranted;
  final bool exactAlarmsGranted;
}

abstract class NotificationScheduler {
  Future<NotificationPermissionResult> requestPermissions();

  Future<void> replaceAll(List<CourseReminder> reminders);

  Future<void> cancelAll();
}

class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _campusTimeZone = 'Asia/Shanghai';
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'course_reminders',
      '上课提醒',
      channelDescription: '在课程开始前提醒',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initializing;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _initialize() => _initializing ??= _initializeOnce();

  Future<void> _initializeOnce() async {
    timezone_data.initializeTimeZones();
    timezone.setLocalLocation(timezone.getLocation(_campusTimeZone));
    if (!_isAndroid) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_school'),
      ),
    );
  }

  @override
  Future<NotificationPermissionResult> requestPermissions() async {
    await _initialize();
    if (!_isAndroid) {
      return const NotificationPermissionResult(
        notificationsGranted: false,
        exactAlarmsGranted: false,
      );
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!;
    final notificationsGranted =
        await android.requestNotificationsPermission() ?? true;
    if (!notificationsGranted) {
      return const NotificationPermissionResult(
        notificationsGranted: false,
        exactAlarmsGranted: false,
      );
    }

    var exactAlarmsGranted =
        await android.canScheduleExactNotifications() ?? false;
    if (!exactAlarmsGranted) {
      exactAlarmsGranted =
          await android.requestExactAlarmsPermission() ?? false;
    }
    return NotificationPermissionResult(
      notificationsGranted: true,
      exactAlarmsGranted: exactAlarmsGranted,
    );
  }

  @override
  Future<void> replaceAll(List<CourseReminder> reminders) async {
    await _initialize();
    if (!_isAndroid) return;
    await _plugin.cancelAllPendingNotifications();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!;
    final exact = await android.canScheduleExactNotifications() ?? false;
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    for (final reminder in reminders) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: timezone.TZDateTime(
          timezone.local,
          reminder.scheduledAt.year,
          reminder.scheduledAt.month,
          reminder.scheduledAt.day,
          reminder.scheduledAt.hour,
          reminder.scheduledAt.minute,
        ),
        notificationDetails: _details,
        androidScheduleMode: mode,
        payload: reminder.payload,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    await _initialize();
    if (_isAndroid) await _plugin.cancelAllPendingNotifications();
  }
}
