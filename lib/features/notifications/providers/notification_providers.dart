import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../timetable/providers/timetable_providers.dart';
import '../../widget/providers/widget_sync_providers.dart';
import '../models/notification_preferences.dart';
import '../services/notification_coordinator.dart';
import '../services/notification_planner.dart';
import '../services/notification_scheduler.dart';

final notificationPreferencesProvider = StreamProvider<NotificationPreferences>(
  (ref) async* {
    await ref.watch(databaseReadyProvider.future);
    yield* ref
        .watch(databaseProvider)
        .watchSettings()
        .map(NotificationPreferences.fromSettings);
  },
);

final notificationSchedulerProvider = Provider<NotificationScheduler>(
  (ref) => LocalNotificationScheduler(),
);

final notificationCoordinatorProvider = Provider<NotificationCoordinator>((
  ref,
) {
  final database = ref.watch(databaseProvider);
  final coordinator = NotificationCoordinator(
    scheduler: ref.watch(notificationSchedulerProvider),
    loadPreferences: () async =>
        NotificationPreferences.fromSettings(await database.allSettings()),
    loadReminders: (preferences) async {
      final semester = await database.currentSemester();
      if (semester == null) return const [];
      final courses = await database.watchCourses(semester.id).first;
      return const NotificationPlanner().build(
        semester: semester,
        courses: courses,
        sectionTimes: await database.allSectionTimes(),
        now: DateTime.now(),
        minutesBefore: preferences.minutesBefore,
      );
    },
    persistSetting: database.setSetting,
  );
  ref.listen(allCoursesProvider, (_, _) => unawaited(coordinator.flush()));
  ref.listen(semestersProvider, (_, _) => unawaited(coordinator.flush()));
  ref.listen(sectionTimesProvider, (_, _) => unawaited(coordinator.flush()));
  ref.listen(
    notificationPreferencesProvider,
    (_, _) => unawaited(coordinator.flush()),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
