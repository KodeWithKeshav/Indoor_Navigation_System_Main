import 'dart:math';
import 'package:flutter/material.dart';

/// A compact compass overlay for the AR navigation screen.
///
/// Shows a semi-transparent compass ring with:
/// - A cyan needle pointing to the target bearing (next waypoint direction)
/// - A white tick marking current device heading
/// - N/E/S/W labels
class ArCompassOverlay extends StatefulWidget {
  final double? currentHeading; // 0..360
  /// The absolute world bearing the user should walk toward (0..360).
  /// Computed as (currentHeading + instructionRelativeBearing) by the caller.
  /// The compass ring rotates by -currentHeading, so the needle appears at
  /// the correct *relative* screen position automatically.
  final double targetBearing;

  const ArCompassOverlay({
    super.key,
    required this.currentHeading,
    required this.targetBearing,
  });

  @override
  State<ArCompassOverlay> createState() => _ArCompassOverlayState();
}

class _ArCompassOverlayState extends State<ArCompassOverlay> {
  double _cumulativeRotation = 0.0;
  double _previousHeading = 0.0;

  @override
  void initState() {
    super.initState();
    final heading = widget.currentHeading ?? 0;
    _cumulativeRotation = -heading * (pi / 180);
    _previousHeading = heading;
  }

  @override
  void didUpdateWidget(ArCompassOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newHeading = widget.currentHeading ?? 0;

    // Shortest-path delta to avoid 360° wrapping spin
    var delta = newHeading - _previousHeading;
    while (delta > 180) delta -= 360;
    while (delta < -180) delta += 360;

    _cumulativeRotation -= delta * (pi / 180);
    _previousHeading = newHeading;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Navigation compass',
      child: SizedBox(
        width: 72,
        height: 72,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _cumulativeRotation),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          builder: (context, rotationAngle, _) {
            return CustomPaint(
              painter: _CompassPainter(
                rotationAngle: rotationAngle,
                targetBearing: widget.targetBearing,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double rotationAngle; // Radians to rotate compass (cumulative)
  final double targetBearing;

  _CompassPainter({required this.rotationAngle, required this.targetBearing});

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
