import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../models/course.dart';
import '../../../models/semester.dart';
import '../../../services/semester_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final databaseReadyProvider = FutureProvider<void>(
  (ref) => ref.watch(databaseProvider).ensureDefaults(),
);

final semestersProvider = StreamProvider<List<Semester>>((ref) async* {
  await ref.watch(databaseReadyProvider.future);
  yield* ref.watch(databaseProvider).watchSemesters();
});

final activeSemesterProvider = Provider<Semester?>(
  (ref) => ref.watch(semestersProvider).value?.firstOrNull,
);

class SelectedWeek extends Notifier<int> {
  @override
  int build() {
    final semester = ref.watch(activeSemesterProvider);
    if (semester == null) return 1;
    final value = const SemesterService().currentWeek(semester, DateTime.now());
    return value == 0 ? 1 : value;
  }

  void previous() {
    if (state > 1) state--;
  }

  void next(int totalWeeks) {
    if (state < totalWeeks) state++;
  }

  void goToCurrent() {
    final semester = ref.read(activeSemesterProvider);
    if (semester == null) return;
    final value = const SemesterService().currentWeek(semester, DateTime.now());
    state = value == 0 ? 1 : value;
  }
}

final selectedWeekProvider = NotifierProvider<SelectedWeek, int>(
  SelectedWeek.new,
);

final visibleCoursesProvider = StreamProvider<List<Course>>((ref) async* {
  await ref.watch(databaseReadyProvider.future);
  final semester = ref.watch(activeSemesterProvider);
  if (semester == null) {
    yield const [];
    return;
  }
  final week = ref.watch(selectedWeekProvider);
  yield* ref.watch(databaseProvider).watchCourses(semester.id, week: week);
});

final courseProvider = FutureProvider.family<Course?, String>((ref, id) async {
  await ref.watch(databaseReadyProvider.future);
  return ref.watch(databaseProvider).findCourse(id);
});
