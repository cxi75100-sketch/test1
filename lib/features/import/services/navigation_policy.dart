/// 导航策略——纯 Dart 逻辑，可脱离 WebView 进行单元测试。
///
/// 职责：判断一个 URI 是否应被允许加载；返回脱敏结果供 UI 展示。
/// 不包含任何平台或 WebView 依赖。
library;

import '../../../models/school.dart';

/// 导航决策。
enum NavigationDecision { allow, block }

/// 导航决策的原因，供 UI 展示脱敏信息。
enum NavigationReason {
  /// 受信任域名，允许加载。
  trustedHost,

  /// 非 http/https scheme（javascript / data / file / ftp 等）。
  disallowedScheme,

  /// http/https 但域名不在白名单中。
  unknownHost,
}

/// 单次导航评估结果。
class NavigationEval {
  const NavigationEval({required this.decision, required this.reason});
  final NavigationDecision decision;
  final NavigationReason reason;

  bool get isAllowed => decision == NavigationDecision.allow;
}

/// 导航策略：根据 [NcpuSchoolConfig] 的白名单与 scheme 约束评估 URI。
class NavigationPolicy {
  const NavigationPolicy();

  /// 评估 [uri] 是否应被允许加载。
  NavigationEval evaluate(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (!NcpuSchoolConfig.allowedSchemes.contains(scheme)) {
      return const NavigationEval(
        decision: NavigationDecision.block,
        reason: NavigationReason.disallowedScheme,
      );
    }
    if (NcpuSchoolConfig.accepts(uri)) {
      return const NavigationEval(
        decision: NavigationDecision.allow,
        reason: NavigationReason.trustedHost,
      );
    }
    return const NavigationEval(
      decision: NavigationDecision.block,
      reason: NavigationReason.unknownHost,
    );
  }

  /// 将 [uri] 脱敏为 UI 可展示的域名字符串。
  /// 仅返回 host（+port），不输出 path / query / fragment。
  String redactedHost(Uri uri) => uri.hasPort
      ? '${uri.host}:${uri.port}'
      : uri.host;
}
