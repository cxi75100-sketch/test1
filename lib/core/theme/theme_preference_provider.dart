import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/timetable/providers/timetable_providers.dart';
import 'theme_preference.dart';

final themePreferenceProvider = StreamProvider<ThemePreference>((ref) async* {
  await ref.watch(databaseReadyProvider.future);
  yield* ref
      .watch(databaseProvider)
      .watchSettings()
      .map(ThemePreference.fromSettings);
});

Future<void> setThemePreference(WidgetRef ref, ThemePreference preference) =>
    ref
        .read(databaseProvider)
        .setSetting(themeModeSettingKey, preference.storageValue);
