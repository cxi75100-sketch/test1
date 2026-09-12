import 'dart:async';

import '../models/notification_preferences.dart';
import 'notification_planner.dart';
import 'notification_scheduler.dart';

enum NotificationEnableResult {
  enabled,
  enabledInexact,
  permissionDenied,
  failed,
}

class NotificationCoordinator {
  NotificationCoordinator({
    required this.scheduler,
    required this.loadPreferences,
    required this.loadReminders,
    required this.persistSetting,
  });

  final NotificationScheduler scheduler;
  final Future<NotificationPreferences> Function() loadPreferences;
  final Future<List<CourseReminder>> Function(
    NotificationPreferences preferences,
  )
  loadReminders;
  final Future<void> Function(String key, String value) persistSetting;

  bool _running = false;
  bool _pendingAgain = false;
  bool _disposed = false;
  Completer<bool>? _activeFlush;

  Future<NotificationEnableResult> setEnabled(bool enabled) async {
    if (!enabled) {
      try {
        await persistSetting(notificationEnabledSettingKey, 'false');
        await scheduler.cancelAll();
        return NotificationEnableResult.enabled;
      } catch (_) {
        return NotificationEnableResult.failed;
      }
    }
    try {
      final permission = await scheduler.requestPermissions();
      if (!permission.notificationsGranted) {
        return NotificationEnableResult.permissionDenied;
      }
      await persistSetting(notificationEnabledSettingKey, 'true');
      final scheduled = await flush();
      if (!scheduled) {
        await persistSetting(notificationEnabledSettingKey, 'false');
        return NotificationEnableResult.failed;
      }
      return permission.exactAlarmsGranted
          ? NotificationEnableResult.enabled
          : NotificationEnableResult.enabledInexact;
    } catch (_) {
      return NotificationEnableResult.failed;
    }
  }

  Future<void> setMinutesBefore(int minutes) async {
    if (!notificationMinuteOptions.contains(minutes)) {
      throw ArgumentError.value(minutes, 'minutes');
    }
    await persistSetting(notificationMinutesSettingKey, '$minutes');
    await flush();
  }

  Future<bool> flush() async {
    if (_disposed) return false;
    if (_running) {
      _pendingAgain = true;
      return _activeFlush!.future;
    }
    _running = true;
    final completer = Completer<bool>();
    _activeFlush = completer;
    var succeeded = true;
    try {
      do {
        _pendingAgain = false;
        await _applyOnce();
      } while (_pendingAgain && !_disposed);
    } catch (_) {
      // 通知是可选副作用；权限或 OEM 调度失败不应影响课表主流程。
      succeeded = false;
    } finally {
      _running = false;
      _activeFlush = null;
      completer.complete(succeeded);
    }
    return succeeded;
  }

  void dispose() => _disposed = true;

  Future<void> _applyOnce() async {
    final preferences = await loadPreferences();
    if (!preferences.enabled) {
      await scheduler.cancelAll();
      return;
    }
    await scheduler.replaceAll(await loadReminders(preferences));
  }
}
