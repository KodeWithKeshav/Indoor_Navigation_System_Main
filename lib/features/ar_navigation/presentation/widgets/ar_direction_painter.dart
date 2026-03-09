import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../providers/ar_navigation_provider.dart';

/// CustomPainter that renders a single 3D perspective-projected arrow
/// on the ground plane of the camera feed.
///
/// The arrow:
/// - Appears to lie flat on the ground, pointing toward the next waypoint
/// - Rotates based on the instruction's relative bearing (left/right/straight)
/// - Uses perspective foreshortening (trapezoid shape) for 3D depth
/// - Changes color: green (on-track), yellow (slight turn), red (off-track)
/// - Pulses with a glow animation
/// - Uses device pitch to anchor to the ground plane:
///   * Camera at sky → arrow at very bottom (ground is below)
///   * Camera horizontal → arrow in lower third
///   * Camera at floor → arrow moves toward center (looking at ground)
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
    // DeviceOrientationService pitch values (after atan2 + clamp):
    //   +90° = phone vertical (camera looks forward/horizontal)
    //   +45° = phone tilted slightly toward floor
    //     0° = phone at ~45° from vertical
    //   -90° = phone flat face-up (camera at ceiling) or looking at ground
    //
    // For AR ground projection:
    //   Phone vertical (+90): arrow in lower third (user looking ahead)
    //   Phone tilted down (+45): arrow moves up (ground is more visible)
    //   Phone flat (0 or below): arrow near center (looking straight at floor)

    // Map pitch from [-90, +90] to arrow Y position
    // Higher pitch (vertical) → lower on screen (ground is in lower view)
    // Lower pitch (tilted down) → higher on screen (ground fills more view)
    final pitchNorm = ((devicePitch + 90.0) / 180.0).clamp(0.0, 1.0);
    // pitchNorm: 0.0 = phone flat (-90°), 0.5 = 45° angle, 1.0 = vertical (+90°)

    // Y position: center (0.45) when looking at floor → lower-third (0.72) when vertical
    final groundY = size.height * (0.45 + pitchNorm * 0.27);

    // Don't paint if arrow is completely off-screen
    if (groundY > size.height * 1.1 || groundY < 0) return;

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

    // Rotate arrow to point in the instruction direction.
    // bearing: -90 = left, 0 = forward, +90 = right, ±180 = behind
    final rotationRad = bearing * (pi / 180.0);
    canvas.rotate(rotationRad);

    // --- 3D Perspective transform ---
    // Simulates the arrow lying flat on the ground plane.
    // When phone is vertical (looking ahead): stronger perspective (pitchNorm=1)
    // When phone is flat looking at floor: zero tilt, arrow drawn flat (pitchNorm=0)
    final perspectiveStrength = 0.5 + pitchNorm * 0.4;

    final Matrix4 perspective = Matrix4.identity()
      ..setEntry(3, 2, 0.003 * perspectiveStrength) // Z-perspective
      ..rotateX(
        pitchNorm * 1.2,
      ); // TILT: 0.0 when looking down, 1.2rad (70deg) when vertical

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
    // ArNavigationState now has proper == override, so this works correctly.
    return oldDelegate.arState != arState ||
        oldDelegate.pulseValue != pulseValue ||
        (oldDelegate.devicePitch - devicePitch).abs() > 0.5;
  }
}
