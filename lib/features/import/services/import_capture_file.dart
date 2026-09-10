import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'import_capture.dart';

/// 仅 Debug 使用：把脱敏报告写到应用外部目录，方便直接用 adb 取走。
///
/// 写入内容是 [buildImportCaptureReport] 的结果——学号、姓名、密码、
/// Cookie、Session、Token 在生成阶段就已被替换，落盘的从来不是原始报文。
class ImportCaptureFile {
  const ImportCaptureFile();

  /// 汇总文件：每次采集都覆盖写，始终保存最新完整列表。
  static const String latestFileName = 'import_capture_latest.txt';

  Future<String?> saveLatest(List<ImportCaptureEntry> entries) =>
      save(entries, fileName: latestFileName);

  Future<String?> save(
    List<ImportCaptureEntry> entries, {
    String? fileName,
  }) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) return null;
      final name =
          fileName ??
          'import_capture_${DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-')}.txt';
      final file = File('${directory.path}/$name');
      await file.writeAsString(buildImportCaptureReport(entries));
      return file.path;
    } on Exception {
      // 写文件失败不影响采集本身。
      return null;
    }
  }
}
