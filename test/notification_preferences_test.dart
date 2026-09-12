import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/features/notifications/models/notification_preferences.dart';

void main() {
  test('通知偏好默认关闭且提前 15 分钟', () {
    expect(
      NotificationPreferences.fromSettings(const {}),
      const NotificationPreferences(),
    );
  });

  test('只接受允许的提前分钟数', () {
    expect(
      NotificationPreferences.fromSettings(const {
        notificationEnabledSettingKey: 'true',
        notificationMinutesSettingKey: '30',
      }),
      const NotificationPreferences(enabled: true, minutesBefore: 30),
    );
    expect(
      NotificationPreferences.fromSettings(const {
        notificationEnabledSettingKey: 'true',
        notificationMinutesSettingKey: '99',
      }).minutesBefore,
      defaultNotificationMinutes,
    );
  });
}
