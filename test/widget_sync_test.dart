import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/core/database/app_database.dart';
import 'package:ncpu_timetable/features/timetable/providers/timetable_providers.dart';
import 'package:ncpu_timetable/features/widget/providers/widget_sync_providers.dart';
import 'package:ncpu_timetable/features/widget/services/widget_bridge.dart';
import 'package:ncpu_timetable/models/course.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(WidgetBridge.channelName);

  late AppDatabase database;
  late List<Map<String, dynamic>> pushed;

  void mockNativeHandler() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == WidgetBridge.updatePayloadMethod) {
            pushed.add(jsonDecode(call.arguments as String) as Map<String, dynamic>);
            return true;
          }
          return null;
        });
  }

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    pushed = [];
    mockNativeHandler();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await database.close();
  });

  /// 启动同步监听并等待首帧推送完成。
  Future<ProviderContainer> startSync() async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    final subscription = container.listen(widgetSyncProvider, (_, _) {});
    addTearDown(subscription.close);
    addTearDown(container.dispose);
    await container.read(databaseReadyProvider.future);
    await container.read(allCoursesProvider.future);
    await pumpEventQueue();
    return container;
  }

  test('原生通道缺失时推送返回 false 且不抛异常', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);

    expect(await const WidgetBridge().pushPayload('{"schemaVersion":1}'), isFalse);
  });

  test('启动后推送的载荷包含默认学期与默认节次时间', () async {
    await startSync();

    expect(pushed, isNotEmpty);
    final payload = pushed.last;
    expect(payload['schemaVersion'], 1);
    final semester = payload['semester'] as Map<String, dynamic>;
    expect(semester['totalWeeks'], 20);
    expect(payload['courses'], isEmpty);
    expect((payload['sectionTimes'] as List), hasLength(10));
  });

  test('新增课程后重新推送包含该课程的快照', () async {
    final container = await startSync();
    final semester = container.read(activeSemesterProvider);
    expect(semester, isNotNull);
    final countBefore = pushed.length;

    await database.upsertCourse(
      Course(
        id: 'manual-1',
        name: '高等数学',
        classroom: 'A101',
        weekday: 1,
        startSection: 1,
        endSection: 2,
        weeks: const [1, 2, 3],
        semesterId: semester!.id,
        colorKey: 0,
      ),
    );
    await pumpEventQueue();

    expect(pushed.length, greaterThan(countBefore));
    final courses = pushed.last['courses'] as List;
    expect(courses, hasLength(1));
    expect((courses.single as Map<String, dynamic>)['name'], '高等数学');
  });

  test('删除课程后推送的快照不再包含该课程', () async {
    final container = await startSync();
    final semester = container.read(activeSemesterProvider);
    await database.upsertCourse(
      Course(
        id: 'manual-1',
        name: '高等数学',
        weekday: 1,
        startSection: 1,
        endSection: 2,
        weeks: const [1],
        semesterId: semester!.id,
        colorKey: 0,
      ),
    );
    await pumpEventQueue();
    final countBeforeDelete = pushed.length;

    await database.deleteCourse('manual-1');
    await pumpEventQueue();

    expect(pushed.length, greaterThan(countBeforeDelete));
    expect(pushed.last['courses'], isEmpty);
  });
}
