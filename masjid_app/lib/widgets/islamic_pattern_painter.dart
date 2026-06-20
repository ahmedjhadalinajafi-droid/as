import 'dart:math';
import 'package:flutter/material.dart';

class IslamicPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;

  const IslamicPatternPainter({
    this.color = const Color(0xFFFFD700),
    this.opacity = 0.07,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 60.0;
    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cx = c * spacing;
        final cy = r * spacing;
        _drawStar(canvas, paint, Offset(cx, cy), 20);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double radius) {
    const points = 8;
    final innerRadius = radius * 0.45;
    final path = Path();

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * pi / points) - pi / 2;
      final r = i.isEven ? radius : innerRadius;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(IslamicPatternPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}
