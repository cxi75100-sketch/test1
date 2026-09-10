import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../adapters/ncpu_adapter.dart';
import '../adapters/school_adapter.dart';
import '../services/import_session_cleaner.dart';

/// 当前学校适配器。首版固定为南昌工学院。
final schoolAdapterProvider = Provider<SchoolAdapter>(
  (ref) => const NcpuAdapter(),
);

/// 离开导入页时的 WebView 会话清理器。可在测试中替换以校验调用时机。
final importSessionCleanerProvider = Provider<ImportSessionCleaner>(
  (ref) => const ImportSessionCleaner(),
);
