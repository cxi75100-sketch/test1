import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/course.dart';
import '../../../models/section_time.dart';
import '../../timetable/providers/timetable_providers.dart';
import '../services/widget_bridge.dart';
import '../services/widget_payload_builder.dart';

/// 当前学期的全部课程（不做教学周过滤）。
///
/// 桌面小组件需要整周数据后按设备日期自行筛选，因此这里与课表页的
/// [visibleCoursesProvider] 不同，不按选中周过滤。
final allCoursesProvider = StreamProvider<List<Course>>((ref) async* {
  await ref.watch(databaseReadyProvider.future);
  final semester = ref.watch(activeSemesterProvider);
  if (semester == null) {
    yield const [];
    return;
  }
  yield* ref.watch(databaseProvider).watchCourses(semester.id);
});

/// 节次时间表，小组件用它把节次序号换算成上课钟点。
final sectionTimesProvider = StreamProvider<List<SectionTime>>((ref) async* {
  await ref.watch(databaseReadyProvider.future);
  yield* ref.watch(databaseProvider).watchSectionTimes();
});

final widgetBridgeProvider = Provider<WidgetBridge>(
  (ref) => const WidgetBridge(),
);

/// 把最新课表快照推送给桌面小组件。
///
/// 推送属于可选副作用：任何失败都静默降级，不影响 App 主流程。
class WidgetSync {
  WidgetSync({required this.bridge, required this.loadPayload});

  final WidgetBridge bridge;
  final Future<String> Function() loadPayload;
  bool _running = false;
  bool _pendingAgain = false;
  bool _disposed = false;

  /// 触发一次推送；若已有推送在进行，则在结束后补推一次最新数据，
  /// 避免同一次数据变化引发的多次流事件重复写通道。
  Future<void> flush() async {
    if (_disposed) return;
    if (_running) {
      _pendingAgain = true;
      return;
    }
    _running = true;
    try {
      do {
        _pendingAgain = false;
        await _pushOnce();
      } while (_pendingAgain && !_disposed);
    } finally {
      _running = false;
    }
  }

  void dispose() => _disposed = true;

  Future<void> _pushOnce() async {
    try {
      await bridge.pushPayload(await loadPayload());
    } catch (_) {
      // 读库或载荷构建失败都不应影响 App；下一次数据变化会重新推送。
    }
  }
}

final widgetSyncProvider = Provider<WidgetSync>((ref) {
  final database = ref.watch(databaseProvider);
  final sync = WidgetSync(
    bridge: ref.watch(widgetBridgeProvider),
    loadPayload: () async {
      final semester = await database.firstSemester();
      final courses = semester == null
          ? const <Course>[]
          : await database.watchCourses(semester.id).first;
      return buildWidgetPayload(
        semester: semester,
        courses: courses,
        sectionTimes: await database.allSectionTimes(),
      );
    },
  );
  ref.listen(allCoursesProvider, (_, _) => unawaited(sync.flush()));
  ref.listen(semestersProvider, (_, _) => unawaited(sync.flush()));
  ref.listen(sectionTimesProvider, (_, _) => unawaited(sync.flush()));
  ref.onDispose(sync.dispose);
  return sync;
});
