import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ncpu_timetable/core/database/app_database.dart';
import 'package:ncpu_timetable/features/settings/pages/settings_page.dart';
import 'package:ncpu_timetable/features/timetable/providers/timetable_providers.dart';

void main() {
  // 注：ImportLoginPage 含 InAppWebView，需平台通道；
  // 其渲染与交互验证标记为 BLOCKED，待真机/模拟器验收（TASK-016）。

  testWidgets('设置页包含"教务导入"入口', (tester) async {
    final database = AppDatabase(executor: NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const SettingsPage()),
              GoRoute(
                path: '/import/login',
                builder: (_, _) => Scaffold(body: Center(child: Text('导入页占位'))),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('教务导入'), findsOneWidget);
    expect(find.text('打开候选教务地址（首次进入会提示风险）'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('点击"教务导入"跳转到登录路由', (tester) async {
    final database = AppDatabase(executor: NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const SettingsPage()),
              GoRoute(
                path: '/import/login',
                builder: (_, _) => Scaffold(body: Center(child: Text('导入页占位'))),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('教务导入'));
    await tester.pumpAndSettle();

    // 路由跳转到 /import/login，此处用占位 Scaffold 验证导航成功
    expect(find.text('导入页占位'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
    await tester.pump(const Duration(milliseconds: 1));
  });
}
