import 'package:flutter/services.dart';

/// 与 Android 原生壁面小组件通信的通道。
///
/// 通道名与 Android 侧 `WidgetChannel.NAME` 必须保持一致；小组件是可选能力，
/// 因此推送失败（非 Android 平台、原生未注册、原生解析异常）一律降级为
/// 返回 false，不影响 App 主流程。
class WidgetBridge {
  const WidgetBridge({this.channel = _defaultChannel});

  /// 与 Android 侧 `WidgetChannel.NAME` 一致。
  static const String channelName = 'cn.edu.ncpu.timetable/widget';

  static const MethodChannel _defaultChannel = MethodChannel(channelName);

  /// 原生侧方法名：写入最新载荷并刷新所有小组件实例。
  static const String updatePayloadMethod = 'updatePayload';

  /// 可注入以便在测试中打桩平台调用。
  final MethodChannel channel;

  Future<bool> pushPayload(String payload) async {
    try {
      final updated = await channel.invokeMethod<bool>(
        updatePayloadMethod,
        payload,
      );
      return updated ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
