// =============================================================================
// ar_compass_overlay.dart
//
// A compact, semi-transparent compass widget rendered in the corner of the AR
// navigation screen. It provides a constant directional reference so the user
// can orient themselves relative to the target waypoint without leaving the
// AR view.
//
// The compass ring rotates to match the device's physical heading (via
// compass provider), while a cyan needle always points toward the target
// bearing. This makes it visually obvious which direction the user should
// walk: when the needle points straight up, the user is facing the target.
//
// Anti-spin logic: heading changes are tracked cumulatively using
// shortest-path deltas to avoid the visual "spinning" artifact that occurs
// when heading crosses the 0°/360° boundary (e.g. 359° → 1° would
// otherwise cause a full 358° counter-rotation).
// =============================================================================

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
  /// Accumulated rotation in radians. Instead of setting rotation directly
  /// from heading (which causes wrap-around spins), we add shortest-path
  /// deltas so TweenAnimationBuilder always animates the short way.
  double _cumulativeRotation = 0.0;

  /// Previous heading in degrees, used to compute deltas.
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

    // Compute shortest-path delta to prevent 360° wrapping spin.
    // E.g. going from 350° to 10° yields delta +20°, not -340°.
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
        // Wrap in TweenAnimationBuilder for smooth interpolation between
      // heading changes (200ms ease-out, matching typical compass update rate)
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

/// Custom painter that draws the compass ring, cardinal labels, and
/// target-bearing needle.
///
/// The entire compass is rotated by [rotationAngle] (derived from device
/// heading), so cardinal labels stay world-aligned. The target needle is
/// drawn at [targetBearing] degrees within the rotated frame.
class _CompassPainter extends CustomPainter {
  /// Current cumulative rotation in radians (negative heading, accumulated).
  final double rotationAngle;

  /// Absolute world bearing to the target waypoint (0–360°).
  final double targetBearing;

  _CompassPainter({required this.rotationAngle, required this.targetBearing});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Semi-transparent filled circle as the compass background
    final ringPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, ringPaint);

    // Cyan ring border for visual definition against dark backgrounds
    final borderPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    // Rotate the canvas so the compass ring aligns with the real world.
    // All subsequent drawing (ticks, labels, needle) is in world-space.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    // Draw cardinal direction ticks (N/E/S/W) and their labels.
    // 'N' is highlighted in red for quick north identification.
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

    // Target bearing needle — a cyan line from center pointing toward
    // the next waypoint's absolute world direction.
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

    // Small cyan dot at the needle tip for emphasis
    canvas.drawCircle(needleEnd, 3, Paint()..color = const Color(0xFF38BDF8));

    // White dot at center representing the user's position
    canvas.drawCircle(Offset.zero, 3, Paint()..color = Colors.white);

    canvas.restore();
  }

  /// Only repaint when heading rotation or target bearing actually changes.
  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.targetBearing != targetBearing;
  }
}
