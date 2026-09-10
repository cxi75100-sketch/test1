import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../adapters/ncpu_adapter.dart';
import '../adapters/school_adapter.dart';

/// 当前学校适配器。首版固定为南昌工学院。
final schoolAdapterProvider = Provider<SchoolAdapter>(
  (ref) => const NcpuAdapter(),
);
