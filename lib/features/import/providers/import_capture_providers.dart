import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/import_capture.dart';
import '../services/import_capture_file.dart';

/// 本次会话内采集到的教务请求（仅内存，不落盘、不跨进程）。
class ImportCaptureLog extends Notifier<List<ImportCaptureEntry>> {
  /// 上限，避免课表页面反复轮询时无限增长。
  static const int maxEntries = 200;

  @override
  List<ImportCaptureEntry> build() => const [];

  void add(ImportCaptureEntry entry) {
    final next = [...state, entry];
    state = next.length > maxEntries
        ? next.sublist(next.length - maxEntries)
        : next;
    // 自动落盘，省去手工点「保存到文件」；失败静默忽略。
    unawaited(const ImportCaptureFile().saveLatest(state));
  }

  void clear() {
    state = const [];
  }
}

final importCaptureProvider =
    NotifierProvider<ImportCaptureLog, List<ImportCaptureEntry>>(
      ImportCaptureLog.new,
    );

final importCaptureSanitizerProvider = Provider<ImportCaptureSanitizer>(
  (ref) => const ImportCaptureSanitizer(),
);

/// 最近一次在教务会话内取到的课表原始响应。
///
/// **只保存在内存**：响应里含 `xsxx` 身份字段（姓名、学号、班级、专业），
/// 绝不写入文件、日志或知识库，App 退出即消失。解析只读取课表字段。
class ImportRawTimetable extends Notifier<String?> {
  @override
  String? build() => null;

  void store(String rawJson) => state = rawJson;

  void clear() => state = null;
}

final importRawTimetableProvider =
    NotifierProvider<ImportRawTimetable, String?>(ImportRawTimetable.new);
