import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/features/import/services/import_session_cleaner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('平台通道缺失时静默降级，不把异常抛给调用方', () async {
    // 页面 dispose() 里是 unawaited 调用：这里一旦抛异常就会变成未捕获异常。
    await expectLater(
      const ImportSessionCleaner().clearHttpCache(),
      completes,
    );
  });
}
