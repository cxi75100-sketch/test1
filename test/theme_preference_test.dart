import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/core/database/app_database.dart';
import 'package:ncpu_timetable/core/theme/app_theme.dart';
import 'package:ncpu_timetable/core/theme/theme_preference.dart';
import 'package:ncpu_timetable/features/settings/pages/settings_page.dart';
import 'package:ncpu_timetable/features/timetable/providers/timetable_providers.dart';

void main() {
  test('主题偏好默认跟随系统，非法值安全回退', () {
    expect(ThemePreference.fromSettings(const {}), ThemePreference.system);
    expect(
      ThemePreference.fromSettings(const {themeModeSettingKey: 'unknown'}),
      ThemePreference.system,
    );
    expect(
      ThemePreference.fromSettings(const {themeModeSettingKey: 'dark'}),
      ThemePreference.dark,
    );
  });

  testWidgets('设置页可在三种主题间切换并持久化', (tester) async {
    final database = AppDatabase(executor: NativeDatabase.memory());
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('theme-system')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-light')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-dark')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('theme-dark')));
    await tester.pumpAndSettle();
    expect((await database.allSettings())[themeModeSettingKey], 'dark');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
    await tester.pump(const Duration(milliseconds: 1));
  });
}
