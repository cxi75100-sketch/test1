import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
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
    }
  }

  @override
  Widget build(BuildContext context) {
    // 保持 widgetSyncProvider 存活，让它持续监听课表数据变化。
    ref.watch(widgetSyncProvider);

    return MaterialApp.router(
      title: '南工课表',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
