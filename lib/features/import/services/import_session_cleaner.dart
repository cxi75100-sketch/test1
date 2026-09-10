import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// 离开教务导入页时清理 WebView 残留。
///
/// 只清 HTTP 缓存（含磁盘文件），**不清理 Cookie 与 WebStorage**：这是
/// 用户明确选择的取舍 —— 保留教务登录态，下次导入免登录。代价是教务站
/// 明文 HTTP 会话的 Cookie 仍会落盘，见 `knowledge/decisions.md`。
class ImportSessionCleaner {
  const ImportSessionCleaner();

  /// 清空 WebView 的 HTTP 缓存。
  ///
  /// 用静态方法而非 controller 实例：页面 `dispose()` 时 controller 可能
  /// 已不可用，静态调用不依赖实例。
  ///
  /// **本方法不会抛异常。** 调用点是 `dispose()` 里的 unawaited 调用，
  /// 任何异常都会变成未捕获异常并影响页面退出；而缓存残留只影响存储占用，
  /// 不影响导入功能，因此这里一律吞掉（与 `WidgetBridge` 的降级策略一致）。
  /// 除平台异常外还要吞 `Error`：插件在平台实现未注册时会直接断言失败，
  /// 例如纯 Dart 测试环境。
  Future<void> clearHttpCache() async {
    try {
      await InAppWebViewController.clearAllCache(includeDiskFiles: true);
    } on Object {
      // 清理是尽力而为：失败留给下一次离开页面重试。
    }
  }
}
