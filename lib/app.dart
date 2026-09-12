import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/providers/notification_providers.dart';
import 'features/widget/providers/widget_sync_providers.dart';

class TimetableApp extends ConsumerStatefulWidget {
  const TimetableApp({super.key});

  @override
  ConsumerState<TimetableApp> createState() => _TimetableAppState();
}

class _TimetableAppState extends ConsumerState<TimetableApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 回到前台时可能已经跨天，重新推送一次最新快照。
      unawaited(ref.read(widgetSyncProvider).flush());
      unawaited(ref.read(notificationCoordinatorProvider).flush());
    }
  }

  @override
  Widget build(BuildContext context) {
    // 保持 widgetSyncProvider 存活，让它持续监听课表数据变化。
    ref.watch(widgetSyncProvider);
    // 持续监听课表与提醒偏好，数据变化时重建未来通知。
    ref.watch(notificationCoordinatorProvider);

    return MaterialApp.router(
      title: '南工课表',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
