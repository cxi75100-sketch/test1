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

/// 由课程名生成稳定取色键：同名课程（手动添加或教务导入）永远同色。
int courseColorKeyForName(String name) =>
    name.runes.fold<int>(0, (hash, rune) => (hash * 31 + rune) & 0x7fffffff);
