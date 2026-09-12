import 'package:flutter/material.dart';

/// 页面级轻量氛围背景。
///
/// 只使用静态渐变，不使用 BackdropFilter，避免为了装饰引入持续的 GPU
/// 模糊开销。页面内容仍由 [child] 正常负责滚动和交互。
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [Color(0xFF0E1422), Color(0xFF121A29)]
                  : const [Color(0xFFFAF9F5), Color(0xFFF1F3F8)],
              stops: const [0, 1],
            ),
          ),
        ),
        Positioned(
          top: -190,
          right: -170,
          child: _Glow(
            size: 390,
            color: scheme.primary.withValues(alpha: isDark ? 0.10 : 0.055),
          ),
        ),
        Positioned(
          bottom: -230,
          left: -200,
          child: _Glow(
            size: 410,
            color: scheme.tertiary.withValues(alpha: isDark ? 0.055 : 0.03),
          ),
        ),
        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
}
