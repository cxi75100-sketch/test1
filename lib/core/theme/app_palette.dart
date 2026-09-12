import 'package:flutter/material.dart';

/// 校园数字手账的固定视觉色板。
///
/// 功能状态色仍优先使用 Theme.colorScheme；这些颜色只负责品牌与装饰，
/// 避免页面各自散落一套不一致的十六进制值。
abstract final class AppPalette {
  static const ink = Color(0xFF18213D);
  static const paper = Color(0xFFF8F4EA);
  static const paperBright = Color(0xFFFFFDF7);
  static const cobalt = Color(0xFF5267E8);
  static const coral = Color(0xFFFF806F);
  static const mint = Color(0xFF51C7A9);
  static const sun = Color(0xFFFFC857);
  static const lavender = Color(0xFFA797F4);
  static const mutedInk = Color(0xFF65708A);
  static const line = Color(0xFFE7E0D4);

  static const night = Color(0xFF0E1422);
  static const nightRaised = Color(0xFF171F30);
  static const nightSurface = Color(0xFF1C2537);
  static const nightText = Color(0xFFF2F4FA);
  static const nightMuted = Color(0xFFAAB4C8);
  static const nightLine = Color(0xFF2A3549);
}
