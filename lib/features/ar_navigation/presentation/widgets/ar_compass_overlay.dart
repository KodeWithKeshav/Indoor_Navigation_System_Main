import 'dart:math';
import 'package:flutter/material.dart';

/// A compact compass overlay for the AR navigation screen.
///
/// Shows a semi-transparent compass ring with:
/// - A cyan needle pointing to the target bearing (next waypoint direction)
/// - A white tick marking current device heading
/// - N/E/S/W labels
class ArCompassOverlay extends StatelessWidget {
  final double? currentHeading; // 0..360
  final double targetBearing; // 0..360 (absolute map bearing to next waypoint)

  const ArCompassOverlay({
    super.key,
    required this.currentHeading,
    required this.targetBearing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: -(currentHeading ?? 0) * (pi / 180)),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        builder: (context, rotationAngle, _) {
          return CustomPaint(
            painter: _CompassPainter(
              rotationAngle: rotationAngle,
              targetBearing: targetBearing,
              currentHeading: currentHeading ?? 0,
            ),
          );
        },
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double rotationAngle; // Radians to rotate compass (negative heading)
  final double targetBearing;
  final double currentHeading;

  _CompassPainter({
    required this.rotationAngle,
    required this.targetBearing,
    required this.currentHeading,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Ring background
    final ringPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, ringPaint);

    // Ring border
    final borderPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    // Cardinal direction ticks + labels
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final labels = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2;
      final outerR = radius - 2;
      final innerR = radius - 8;

      final ox = cos(angle - pi / 2) * outerR;
      final oy = sin(angle - pi / 2) * outerR;
      final ix = cos(angle - pi / 2) * innerR;
      final iy = sin(angle - pi / 2) * innerR;

      canvas.drawLine(Offset(ix, iy), Offset(ox, oy), tickPaint);

      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: labels[i] == 'N'
                ? const Color(0xFFEF4444)
                : Colors.white.withValues(alpha: 0.7),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final lx = cos(angle - pi / 2) * (radius - 17);
      final ly = sin(angle - pi / 2) * (radius - 17);
      textPainter.paint(
        canvas,
        Offset(lx - textPainter.width / 2, ly - textPainter.height / 2),
      );
    }

    // Target bearing needle
    final targetAngle = targetBearing * (pi / 180) - pi / 2;
    final needlePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final needleEnd = Offset(
      cos(targetAngle) * (radius - 12),
      sin(targetAngle) * (radius - 12),
    );
    canvas.drawLine(Offset.zero, needleEnd, needlePaint);

    // Needle dot at tip
    canvas.drawCircle(needleEnd, 3, Paint()..color = const Color(0xFF38BDF8));

    // Center dot
    canvas.drawCircle(Offset.zero, 3, Paint()..color = Colors.white);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.targetBearing != targetBearing;
  }
}
