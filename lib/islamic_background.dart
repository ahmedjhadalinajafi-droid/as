import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A reusable page background that paints a subtle repeating Islamic
/// geometric pattern (8-pointed stars) over the app's cream / dark base.
///
/// Wrap a page's [Scaffold] with this and set the Scaffold's
/// `backgroundColor` to [Colors.transparent] so the pattern shows through
/// behind cards and list items — exactly like the reference مفاتيح الجنان UI.
class IslamicPatternBackground extends StatelessWidget {
  final Widget child;

  /// When true the base cream / dark fill is painted first. Set to false if
  /// the child already supplies its own opaque base color.
  final bool fillBase;

  const IslamicPatternBackground({
    super.key,
    required this.child,
    this.fillBase = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base =
        isDark ? const Color(0xFF0A1628) : const Color(0xFFF3EFE2);
    final line = isDark
        ? const Color(0xFFC9A843).withOpacity(0.045)
        : const Color(0xFF1B3D6F).withOpacity(0.05);

    return Container(
      color: fillBase ? base : null,
      child: CustomPaint(
        painter: IslamicPatternPainter(line),
        child: child,
      ),
    );
  }
}

// ─── Islamic Geometric Pattern Painter ───────────────────────────────────────

class IslamicPatternPainter extends CustomPainter {
  final Color color;
  IslamicPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    const cell = 64.0;
    const half = cell / 2;

    // Staggered grid of 8-pointed stars
    int row = 0;
    for (double y = -cell; y < size.height + cell; y += half) {
      final xOffset = (row % 2 == 0) ? 0.0 : half;
      for (double x = -cell + xOffset; x < size.width + cell; x += cell) {
        _drawStar(canvas, paint, Offset(x, y), cell * 0.42);
        _drawInnerSquare(canvas, paint, Offset(x, y), cell * 0.18);
      }
      row++;
    }

    // Connecting lines between stars
    row = 0;
    for (double y = -cell; y < size.height + cell; y += half) {
      final xOffset = (row % 2 == 0) ? 0.0 : half;
      for (double x = -cell + xOffset; x < size.width + cell; x += cell) {
        _drawConnectors(canvas, paint, Offset(x, y), cell * 0.42, half);
      }
      row++;
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset c, double r) {
    final path = Path();
    final innerR = r * 0.42;
    for (int i = 0; i < 16; i++) {
      final angle = i * math.pi / 8 - math.pi / 2;
      final radius = i % 2 == 0 ? r : innerR;
      final pt = Offset(
        c.dx + radius * math.cos(angle),
        c.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawInnerSquare(Canvas canvas, Paint paint, Offset c, double r) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 4;
      final pt =
          Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawConnectors(Canvas canvas, Paint p, Offset c, double r, double half) {
    final tipDist = r;
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 - math.pi / 8;
      final tip = Offset(
        c.dx + tipDist * math.cos(angle),
        c.dy + tipDist * math.sin(angle),
      );
      final nextAngle = angle + math.pi / 8 * 2;
      final nextTip = Offset(
        c.dx + tipDist * math.cos(nextAngle),
        c.dy + tipDist * math.sin(nextAngle),
      );
      canvas.drawLine(tip, nextTip, p);
    }
  }

  @override
  bool shouldRepaint(IslamicPatternPainter old) => old.color != color;
}
