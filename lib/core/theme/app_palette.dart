import 'package:flutter/material.dart';

/// 课表 App 的固定视觉色板。
///
/// 功能状态色仍优先使用 Theme.colorScheme；这些颜色只负责品牌与装饰，
/// 避免页面各自散落一套不一致的十六进制值。课程色不在这里：课程卡一律
/// 用 `courseSurfaceTint` / `courseBadgeTint` 从课程色混合，不做固定配色。
abstract final class AppPalette {
  /// 日间正文色，同时被 `ColorScheme.onSurface` 使用，不是品牌深蓝。
  static const ink = Color(0xFF1B2430);
  static const paper = Color(0xFFF7F8FA);
  static const paperBright = Color(0xFFFFFFFF);
  static const cobalt = Color(0xFF3567D6);
  static const coral = Color(0xFFFF806F);
  static const mint = Color(0xFF51C7A9);
  static const sun = Color(0xFFFFC857);
  static const lavender = Color(0xFFA797F4);
  static const mutedInk = Color(0xFF667085);
  static const line = Color(0xFFE4E7EC);

  // 夜间色不是日间色的机械反转：底色带一点蓝灰，抬升层逐级变亮，
  // 暖白文字则避免纯白在大面积深色背景上的刺眼感。
  static const night = Color(0xFF101521);
  static const nightSurface = Color(0xFF171D29);
  static const nightRaised = Color(0xFF1C2432);
  static const nightHigh = Color(0xFF242E3E);
  static const nightHighest = Color(0xFF2D394B);
  static const nightText = Color(0xFFE9EDF5);
  static const nightMuted = Color(0xFF9AA7BA);
  static const nightLine = Color(0xFF344154);
}
