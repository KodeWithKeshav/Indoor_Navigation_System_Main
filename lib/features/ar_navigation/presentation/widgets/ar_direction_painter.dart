import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../providers/ar_navigation_provider.dart';

/// CustomPainter that renders a large directional arrow at screen center
/// with trailing chevrons creating a pseudo-3D "path ahead" effect.
///
/// The lead arrow:
/// - Is always visible and large (not based on waypoint projection)
/// - Rotates based on relative bearing to next waypoint
/// - Changes color: green (on-track), yellow (slight turn), red (off-track)
/// - Pulses with a glow animation
///
/// Trail chevrons:
/// - Drawn behind the lead arrow, progressively smaller and more transparent
/// - Create the illusion of a path stretching into the distance
class ArDirectionPainter extends CustomPainter {
  final ArNavigationState arState;
  final double pulseValue; // 0.0..1.0 animation value for lead arrow pulse

  ArDirectionPainter({required this.arState, this.pulseValue = 0.5});

  @override
  void paint(Canvas canvas, Size size) {
    if (!arState.hasData) return;

    final bearing = arState.relativeBearing; // -180..180

    // === LEAD ARROW ===
    // Position: center of screen, shifted horizontally by bearing
    // When bearing is 0, arrow is dead center. At ±90°, it's at the edges.
    final centerX =
        size.width / 2 +
        (bearing / 90.0).clamp(-1.0, 1.0) * (size.width * 0.35);
    final centerY = size.height * 0.45; // Slightly above center

    final leadSize = 60.0 + pulseValue * 8.0; // Pulsing size

    // Arrow color from on-track status
    Color arrowColor;
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

    // Glow effect
    final glowPaint = Paint()
      ..color = arrowColor.withValues(alpha: 0.25 + pulseValue * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28)
      ..style = PaintingStyle.fill;
    _drawArrow(canvas, centerX, centerY, leadSize * 1.4, bearing, glowPaint);

    // Filled arrow
    final fillPaint = Paint()
      ..color = arrowColor.withValues(alpha: 0.85 + pulseValue * 0.15)
      ..style = PaintingStyle.fill;
    _drawArrow(canvas, centerX, centerY, leadSize, bearing, fillPaint);

    // White outline
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _drawArrow(canvas, centerX, centerY, leadSize, bearing, outlinePaint);

    // === TRAIL CHEVRONS ===
    for (int i = 1; i <= arState.trailCount; i++) {
      final depthScale = 1.0 / (1.0 + i * 0.5);
      final trailSize = 35.0 * depthScale;
      final opacity = (0.6 * depthScale).clamp(0.1, 0.5);

      // Trail chevrons extend "into the distance" — same X direction, moving toward center Y
      final trailX =
          size.width / 2 +
          (bearing / 90.0).clamp(-1.0, 1.0) * (size.width * 0.35) * depthScale;
      final trailY =
          centerY - (i * 45.0 * depthScale); // Stack upward toward "horizon"

      // Trail uses electric blue
      final trailPaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      _drawChevron(canvas, trailX, trailY, trailSize, trailPaint);

      // Thin outline
      final trailOutline = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.6)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      _drawChevron(canvas, trailX, trailY, trailSize, trailOutline);
    }

    // === NEXT LANDMARK LABEL ===
    if (arState.nextLandmarkName != null &&
        arState.nextLandmarkName!.isNotEmpty) {
      _drawLandmarkLabel(
        canvas,
        size,
        centerX,
        centerY - leadSize - 20,
        arState.nextLandmarkName!,
      );
    }
  }

  /// Draws a directional arrow rotated by bearing angle.
  void _drawArrow(
    Canvas canvas,
    double cx,
    double cy,
    double size,
    double bearing,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(cx, cy);

    // Rotate arrow: 0° = pointing up, positive = clockwise
    // But we clamp rotation to avoid the arrow spinning wildly
    final rotationDeg = bearing.clamp(-90.0, 90.0);
    canvas.rotate(rotationDeg * pi / 180);

    final path = Path();
    // Upward-pointing arrow
    path.moveTo(0, -size * 0.5); // Top tip
    path.lineTo(size * 0.35, size * 0.2); // Bottom right
    path.lineTo(size * 0.12, size * 0.05); // Inner right
    path.lineTo(0, -size * 0.15); // Inner top
    path.lineTo(-size * 0.12, size * 0.05); // Inner left
    path.lineTo(-size * 0.35, size * 0.2); // Bottom left
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  /// Draws a simple upward-pointing chevron (no rotation).
  void _drawChevron(
    Canvas canvas,
    double cx,
    double cy,
    double size,
    Paint paint,
  ) {
    final path = Path();
    path.moveTo(cx, cy - size * 0.4);
    path.lineTo(cx + size * 0.35, cy + size * 0.15);
    path.lineTo(cx + size * 0.15, cy + size * 0.0);
    path.lineTo(cx, cy - size * 0.1);
    path.lineTo(cx - size * 0.15, cy + size * 0.0);
    path.lineTo(cx - size * 0.35, cy + size * 0.15);
    path.close();
    canvas.drawPath(path, paint);
  }

  /// Draws a floating label pill above the lead arrow.
  void _drawLandmarkLabel(
    Canvas canvas,
    Size canvasSize,
    double cx,
    double labelY,
    String text,
  ) {
    final textStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );

    final paragraphStyle = ui.ParagraphStyle(
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '...',
    );

    final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(text);

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: canvasSize.width * 0.5));

    final textWidth = paragraph.longestLine;
    final textHeight = paragraph.height;

    // Clamp label position within screen bounds
    final clampedX = cx.clamp(
      textWidth / 2 + 16,
      canvasSize.width - textWidth / 2 - 16,
    );
    final clampedY = labelY.clamp(40.0, canvasSize.height - 200);

    // Background pill
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(clampedX, clampedY),
        width: textWidth + 24,
        height: textHeight + 12,
      ),
      const Radius.circular(12),
    );

    final bgPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.8);
    canvas.drawRRect(bgRect, bgPaint);

    // Cyan border
    final borderPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(bgRect, borderPaint);

    canvas.drawParagraph(
      paragraph,
      Offset(clampedX - textWidth / 2, clampedY - textHeight / 2),
    );
  }

  @override
  bool shouldRepaint(covariant ArDirectionPainter oldDelegate) {
    return oldDelegate.arState != arState ||
        oldDelegate.pulseValue != pulseValue;
  }
}
