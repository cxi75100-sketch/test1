import 'package:flutter/material.dart';

import 'app_palette.dart';

/// 课程卡片与桌面小组件共用的课程配色表。
///
/// 桌面小组件需要把课程颜色推送给 Android 原生侧，因此该常量放在 core/theme，
/// 避免业务逻辑反向依赖 timetable 的 widget 层。
const courseColors = <Color>[
  Color(0xFF5B8FF9),
  Color(0xFF61DDAA),
  Color(0xFF65789B),
  Color(0xFFF6BD16),
  Color(0xFF7262FD),
  Color(0xFF78D3F8),
  Color(0xFF9661BC),
  Color(0xFFF6903D),
];

/// 与课表 UI 完全一致的取色规则。
Color courseColorFor(int colorKey) =>
    courseColors[colorKey.abs() % courseColors.length];

/// 课程详情与课表标签共用的深色渐变。
///
/// 窄课表会在同一屏出现多张卡，因此用较低的 [strength] 保留辨色度，
/// 同时压低大面积高饱和颜色，减少连续查看时的视觉疲劳。
List<Color> courseGradientColors(Color accent, {double strength = 0.82}) => [
  AppPalette.ink,
  Color.lerp(AppPalette.ink, accent, strength)!,
];

/// 由课程名生成稳定取色键：同名课程（手动添加或教务导入）永远同色。
int courseColorKeyForName(String name) =>
    name.runes.fold<int>(0, (hash, rune) => (hash * 31 + rune) & 0x7fffffff);
