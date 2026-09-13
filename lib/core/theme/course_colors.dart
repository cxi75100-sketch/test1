import 'package:flutter/material.dart';

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

/// 课表界面统一的课程色用法：课程色只作为低饱和「面」和淡色标签出现。
///
/// 今日列表卡、整周列课程卡和课程详情头卡共用同一组系数，三处不再各写一套
/// 透明度；也不再把课程色与固定的深色铺底或亮黄标签组合，避免同一屏出现
/// 两种视觉语言。
List<Color> courseSurfaceTint(
  Color accent,
  Color base, {
  required bool isDark,
}) => [
  Color.alphaBlend(accent.withValues(alpha: isDark ? 0.26 : 0.13), base),
  Color.alphaBlend(accent.withValues(alpha: isDark ? 0.08 : 0.025), base),
];

/// 节次签底色：与课程面同源，只用低透明度区分课程。
Color courseBadgeTint(Color accent) => accent.withValues(alpha: 0.18);

/// 由课程名生成稳定取色键：同名课程（手动添加或教务导入）永远同色。
int courseColorKeyForName(String name) =>
    name.runes.fold<int>(0, (hash, rune) => (hash * 31 + rune) & 0x7fffffff);
