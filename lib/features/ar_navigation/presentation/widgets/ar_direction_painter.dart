// =============================================================================
// ar_direction_painter.dart
//
// CustomPainter that renders the primary AR navigation visual: a 3D
// perspective-projected arrow that appears to lie flat on the ground plane
// of the camera feed.
//
// Rendering pipeline:
//   1. Compute ground-plane Y position from device pitch (phone tilt)
//   2. Compute horizontal offset from instruction bearing (left/right/forward)
//   3. Apply 3D perspective transform (rotateX for depth, rotateZ for direction)
//   4. Draw layered arrow: shadow → glow → gradient body → highlight → outline
//   5. Add center depth-cue line and pulse animation
//
// The arrow color indicates navigation status:
//   - Green  = on-track (straight ahead)
//   - Yellow = slight turn needed
//   - Red    = off-track / u-turn required
//
// The arrow smoothly responds to device tilt via [devicePitch] from the
// DeviceOrientationService, creating a convincing ground-anchored effect.
// =============================================================================

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
  /// Current AR navigation state containing bearing, on-track status, etc.
  final ArNavigationState arState;

  /// Pulse animation value (0.0..1.0) used for glow intensity and size oscillation.
  final double pulseValue;

  /// Device pitch from accelerometer (-90..+90°).
  /// Controls the vertical position of the arrow on screen:
  ///   +90° (phone vertical, camera forward) → arrow in lower third
  ///   0°   (phone at 45° tilt)               → arrow in middle area
  ///   -90° (phone flat, camera at ceiling)    → arrow near center
  final double devicePitch;

  ArDirectionPainter({
    required this.arState,
    this.pulseValue = 0.5,
    this.devicePitch = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Don't render if there's no active navigation data
    if (!arState.hasData) return;

    // Relative bearing from the current instruction: 0° = forward,
    // negative = left, positive = right
    final bearing = arState.relativeBearing;

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

    // --- Ground plane Y-position from device pitch ---
    // Normalize pitch from [-90, +90] to [0.0, 1.0]
    // 0.0 = phone flat face-up, 0.5 = 45° tilt, 1.0 = phone vertical
    final pitchNorm = ((devicePitch + 90.0) / 180.0).clamp(0.0, 1.0);

    // Map pitch to screen Y: when looking at floor (low pitch) the arrow
    // sits higher on screen (0.45); when holding phone vertical (high pitch)
    // the arrow drops to the lower third (0.72) where the real ground is
    final groundY = size.height * (0.45 + pitchNorm * 0.27);

    // Don't paint if the computed position is off-screen
    if (groundY > size.height * 1.1 || groundY < 0) return;

    // --- Horizontal offset from bearing ---
    // Bearing is clamped to [-90, +90] for screen mapping; beyond that
    // the arrow would exit the visible area
    final bearingNorm = (bearing / 90.0).clamp(-1.0, 1.0);
    final groundX = size.width / 2 + bearingNorm * (size.width * 0.35);

    // Arrow dimensions — sized relative to screen width with pulse oscillation
    final arrowLength = size.width * 0.28 + pulseValue * 8.0;
    final arrowWidth = arrowLength * 0.55;

    // Arrow color encodes the on-track status from the navigation state
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

    // Move canvas origin to the arrow's ground-plane position
    canvas.save();
    canvas.translate(groundX, groundY);

    // Clamp the rendering bearing to ±120° so the arrow stays partially
    // visible even for u-turn instructions (180° would point it backward
    // and off-screen)
    final renderBearing = bearing.clamp(-120.0, 120.0);
    final rotationRad = renderBearing * (pi / 180.0);

    // --- 3D Perspective transform ---
    // This creates the illusion of the arrow lying flat on the ground.
    // Perspective strength varies with pitch: stronger when phone is vertical
    // (user looking ahead), weaker when phone is tilted down (looking at floor).
    final perspectiveStrength = 0.5 + pitchNorm * 0.4;

    // Transform order matters critically:
    //   1. setEntry(3,2) adds Z-perspective (vanishing point)
    //   2. rotateX tilts the arrow into the ground plane
    //   3. rotateZ rotates the arrow left/right along that ground plane
    // Reversing rotateX and rotateZ would cause left/right arrows to tilt
    // sideways into the floor instead of rotating along it.
    final Matrix4 transform = Matrix4.identity()
      ..setEntry(3, 2, 0.003 * perspectiveStrength) // Z-perspective
      ..rotateX(
        pitchNorm * 1.2,
      ) // TILT: 0.0 when looking down, 1.2rad (70deg) when vertical
      ..rotateZ(rotationRad);

    canvas.transform(transform.storage);

    // --- Draw the multi-layered 3D arrow ---
    // Each layer contributes to the 3D illusion:
    //   1. Shadow   — soft black blur offset below, grounds the arrow
    //   2. Glow     — colored blur halo, pulses with animation
    //   3. Body     — gradient fill (darker at tip, brighter at base) for depth
    //   4. Highlight — white gradient simulating light reflection on top surface
    //   5. Outline  — white stroke for crisp edges
    //   6. Center line — subtle depth cue running along the arrow's spine
    final halfW = arrowWidth / 2;
    final halfL = arrowLength / 2;

    // Layer 1: Ground shadow (slightly larger, offset downward, blurred)
    final shadowPath = _buildArrowPath(halfW * 1.08, halfL * 1.05);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35 + pulseValue * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(2, 4); // Shadow offset
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();

    // Layer 2: Outer glow (color-matched, blurred, pulses with animation)
    final glowPath = _buildArrowPath(halfW * 1.15, halfL * 1.1);
    final glowPaint = Paint()
      ..color = arrowColor.withValues(alpha: 0.2 + pulseValue * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24)
      ..style = PaintingStyle.fill;
    canvas.drawPath(glowPath, glowPaint);

    // Layer 3: Main arrow body — linear gradient from tip (darker) to
    // base (brighter) simulating depth/distance
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

    // Layer 4: Highlight — white-to-transparent gradient simulating light
    // reflecting off the arrow's top surface
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

    // Layer 5: White outline for crisp definition against any background
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(arrowPath, outlinePaint);

    // Layer 6: Inner center line — a subtle vertical stroke that reinforces
    // the 3D depth illusion by implying a central ridge on the arrow
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

  /// Builds a chunky arrow [Path] centered at origin, pointing upward (-Y).
  ///
  /// Shape: pointed tip at top, symmetric wings, notched cutout at the
  /// wing-to-tail junction, and a rectangular tail. The notch creates the
  /// classic "chevron" arrow look.
  ///
  ///       ▲  (tip)
  ///      / \
  ///     /   \
  ///    /     \ (wings)
  ///    \   /
  ///     | |    (tail)
  ///     |_|
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

  /// Only repaint when the navigation state, pulse animation value, or
  /// device pitch changes meaningfully (pitch threshold: 0.5° to avoid
  /// unnecessary repaints from sensor noise).
  @override
  bool shouldRepaint(covariant ArDirectionPainter oldDelegate) {
    // ArNavigationState now has proper == override, so this works correctly.
    return oldDelegate.arState != arState ||
        oldDelegate.pulseValue != pulseValue ||
        (oldDelegate.devicePitch - devicePitch).abs() > 0.5;
  }
}
