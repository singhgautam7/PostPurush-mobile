import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A dashed stadium outline, for "add another one of these".
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter(this.color, {this.radius = Radii.full});

  final Color color;
  final double radius;

  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius.clamp(0, size.shortestSide / 2)),
        ),
      );
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final PathMetric metric in path.computeMetrics()) {
      double at = 0;
      while (at < metric.length) {
        final double end = (at + _dash).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(at, end), paint);
        at = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// A dashed rounded box, which the board uses for the empty params panel.
class DashedBox extends StatelessWidget {
  const DashedBox({
    required this.child,
    required this.color,
    this.radius = Radii.card,
    super.key,
  });

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: DashedBorderPainter(color, radius: radius),
    child: child,
  );
}
