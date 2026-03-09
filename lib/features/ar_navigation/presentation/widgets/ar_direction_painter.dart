import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../providers/ar_navigation_provider.dart';

/// CustomPainter that renders a single 3D perspective-projected arrow
/// on the ground plane of the camera feed.
///
/// The arrow:
/// - Appears to lie flat on the ground, pointing toward the next waypoint
/// - Rotates horizontally based on relative bearing
/// - Uses perspective foreshortening (trapezoid shape) for 3D depth
/// - Changes color: green (on-track), yellow (slight turn), red (off-track)
/// - Pulses with a glow animation
/// - Uses device pitch to adjust vertical position (ground projection)
///
/// Nothing else is drawn — no trail chevrons, no labels, no compass.
class ArDirectionPainter extends CustomPainter {
  final ArNavigationState arState;
  final double pulseValue; // 0.0..1.0 animation value
  final double devicePitch; // -90..90 degrees (phone tilt)

  ArDirectionPainter({
    required this.arState,
    this.pulseValue = 0.5,
    this.devicePitch = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!arState.hasData) return;

    final bearing = arState.relativeBearing; // -180..180

    // --- Ground plane projection ---
    // The arrow should appear to be on the floor ahead of the user.
    // When the phone is tilted down (pitch < 0), the ground is more visible,
    // so the arrow moves up. When held more vertically, it moves down.
    //
    // Pitch mapping: -90 (face-down) → arrow near center
    //                  0 (vertical)   → arrow near bottom
    //                 +45 (tilted up) → arrow at very bottom edge

    // Normalize pitch to a 0..1 range for vertical placement
    // pitch ~-45 to ~+30 is the typical holding range
    final pitchFactor = ((devicePitch + 45) / 75.0).clamp(0.0, 1.0);
    // Map to screen Y: 0.55 (higher, phone tilted down) to 0.82 (lower, phone vertical/up)
    final groundY = size.height * (0.82 - pitchFactor * 0.27);

    // Horizontal offset based on bearing (-90..+90 maps to screen edges)
    final bearingNorm = (bearing / 90.0).clamp(-1.0, 1.0);
    final groundX = size.width / 2 + bearingNorm * (size.width * 0.35);

    // Arrow size — large enough to be clearly visible
    final arrowLength = size.width * 0.28 + pulseValue * 8.0;
    final arrowWidth = arrowLength * 0.55;

    // Arrow color from on-track status
    final Color arrowColor;
    switch (arState.onTrackStatus) {
      case OnTrackStatus.onTrack:
        arrowColor = const Color(0xFF22C55E); // Green
        break;
      case OnTrackStatus.slightTurn:
        arrowColor = const Color(0xFFFBBF24); // Yellow
        break;
      case OnTrackStatus.offTrack:
        arrowColor = const Color(0xFFEF4444); // Red
        break;
    }

    canvas.save();
    canvas.translate(groundX, groundY);

    // Rotate arrow to point in bearing direction
    final rotationRad = bearingNorm * (pi / 3); // max ±60° visual rotation
    canvas.rotate(rotationRad);

    // --- 3D Perspective transform ---
    // Apply a perspective skew to make the arrow look like it's flat on the ground.
    // This simulates a camera looking down at an arrow on the floor.
    //
    // The transform foreshortens the top (far edge) and widens the bottom (near edge),
    // creating a trapezoid shape that reads as "lying flat on the ground".
    final perspectiveStrength = 0.6 + pitchFactor * 0.25; // More extreme when looking down

    final Matrix4 perspective = Matrix4.identity()
      ..setEntry(3, 2, 0.003 * perspectiveStrength) // Z-perspective
      ..rotateX(0.8 + pitchFactor * 0.4); // Tilt the arrow plane to match ground

    canvas.transform(perspective.storage);

    // --- Draw the 3D arrow shape ---
    final halfW = arrowWidth / 2;
    final halfL = arrowLength / 2;

    // Ground shadow (soft, below the arrow)
    final shadowPath = _buildArrowPath(halfW * 1.08, halfL * 1.05);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35 + pulseValue * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(2, 4); // Shadow offset
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();

    // Outer glow
    final glowPath = _buildArrowPath(halfW * 1.15, halfL * 1.1);
    final glowPaint = Paint()
      ..color = arrowColor.withValues(alpha: 0.2 + pulseValue * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24)
      ..style = PaintingStyle.fill;
    canvas.drawPath(glowPath, glowPaint);

    // Main arrow body — gradient fill for 3D depth
    final arrowPath = _buildArrowPath(halfW, halfL);
    final gradientRect = Rect.fromCenter(
      center: Offset.zero,
      width: arrowWidth,
      height: arrowLength,
    );

    final bodyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, -halfL), // tip (far, darker)
        Offset(0, halfL), // base (near, brighter)
        [
          arrowColor.withValues(alpha: 0.6),
          arrowColor.withValues(alpha: 0.95 + pulseValue * 0.05),
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, bodyPaint);

    // Bright edge highlight (top surface simulation)
    final highlightPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(-halfW * 0.3, -halfL),
        Offset(halfW * 0.3, halfL * 0.5),
        [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, highlightPaint);

    // White outline for definition
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(arrowPath, outlinePaint);

    // Inner center line (adds 3D depth cue)
    final centerLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3 + pulseValue * 0.1)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, -halfL * 0.3),
      Offset(0, halfL * 0.5),
      centerLinePaint,
    );

    canvas.restore();
  }

  /// Builds a chunky arrow path centered at origin, pointing upward (negative Y).
  Path _buildArrowPath(double halfWidth, double halfLength) {
    final path = Path();
    // Arrow tip (pointing forward / up)
    path.moveTo(0, -halfLength);
    // Right wing
    path.lineTo(halfWidth, -halfLength * 0.15);
    // Right notch (creates the arrow cutout)
    path.lineTo(halfWidth * 0.35, halfLength * 0.05);
    // Right tail
    path.lineTo(halfWidth * 0.35, halfLength);
    // Left tail
    path.lineTo(-halfWidth * 0.35, halfLength);
    // Left notch
    path.lineTo(-halfWidth * 0.35, halfLength * 0.05);
    // Left wing
    path.lineTo(-halfWidth, -halfLength * 0.15);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant ArDirectionPainter oldDelegate) {
    return oldDelegate.arState != arState ||
        oldDelegate.pulseValue != pulseValue ||
        (oldDelegate.devicePitch - devicePitch).abs() > 0.5;
  }
}
