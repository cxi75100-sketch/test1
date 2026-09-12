const notificationEnabledSettingKey = 'notification_enabled';
const notificationMinutesSettingKey = 'notification_minutes_before';
const notificationMinuteOptions = [5, 10, 15, 30];
const defaultNotificationMinutes = 15;

class NotificationPreferences {
  const NotificationPreferences({
    this.enabled = false,
    this.minutesBefore = defaultNotificationMinutes,
  });

  final bool enabled;
  final int minutesBefore;

  factory NotificationPreferences.fromSettings(Map<String, String> settings) {
    final parsedMinutes = int.tryParse(
      settings[notificationMinutesSettingKey] ?? '',
    );
    return NotificationPreferences(
      enabled: settings[notificationEnabledSettingKey] == 'true',
      minutesBefore: notificationMinuteOptions.contains(parsedMinutes)
          ? parsedMinutes!
          : defaultNotificationMinutes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationPreferences &&
      other.enabled == enabled &&
      other.minutesBefore == minutesBefore;

  @override
  int get hashCode => Object.hash(enabled, minutesBefore);
}
