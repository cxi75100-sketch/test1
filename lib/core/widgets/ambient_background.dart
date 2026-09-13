import 'package:flutter/material.dart';

/// 页面级语义背景，连续承接状态栏、内容区和底部安全区。
///
/// 只用一层纵向渐变加一组低对比线路水印：不再叠加径向环境光斑，
/// 也不用重复纹理，避免在整周这种密集画面上继续堆视觉噪声。
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF111722), Color(0xFF0E131D)]
              : const [Color(0xFFF9FAFC), Color(0xFFF4F6FA)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _RouteWatermarkPainter(
                  primary: scheme.primary,
                  secondary: scheme.tertiary,
                  isDark: isDark,
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// 与首页「线路」语言同源的水印：两条贯穿屏幕的线路曲线，线上标出站点。
///
/// 站点坐标按各自三次贝塞尔曲线取点算过，落在曲线本身上；透明度保持在
/// 「几乎只是纸面纹理」的量级，不参与信息层级。
class _RouteWatermarkPainter extends CustomPainter {
  const _RouteWatermarkPainter({
    required this.primary,
    required this.secondary,
    required this.isDark,
  });

  final Color primary;
  final Color secondary;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final primaryPaint = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.1 : 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final secondaryPaint = Paint()
      ..color = secondary.withValues(alpha: isDark ? 0.07 : 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final upperArc = Path()
      ..moveTo(-size.width * 0.25, size.height * 0.19)
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.03,
        size.width * 0.76,
        size.height * 0.27,
        size.width * 1.2,
        size.height * 0.08,
      );
    final lowerArc = Path()
      ..moveTo(-size.width * 0.15, size.height * 0.78)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.64,
        size.width * 0.72,
        size.height * 0.94,
        size.width * 1.15,
        size.height * 0.72,
      );
    canvas.drawPath(upperArc, primaryPaint);
    canvas.drawPath(lowerArc, secondaryPaint);

    final primaryStation = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.16 : 0.11);
    for (final point in [
      Offset(size.width * 0.18, size.height * 0.13),
      Offset(size.width * 0.48, size.height * 0.15),
      Offset(size.width * 0.78, size.height * 0.16),
    ]) {
      canvas.drawCircle(point, 2.6, primaryStation);
    }
    final secondaryStation = Paint()
      ..color = secondary.withValues(alpha: isDark ? 0.12 : 0.08);
    for (final point in [
      Offset(size.width * 0.29, size.height * 0.75),
      Offset(size.width * 0.62, size.height * 0.8),
      Offset(size.width * 0.95, size.height * 0.79),
    ]) {
      canvas.drawCircle(point, 2.2, secondaryStation);
    }
  }

  @override
  bool shouldRepaint(covariant _RouteWatermarkPainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.isDark != isDark;
}
