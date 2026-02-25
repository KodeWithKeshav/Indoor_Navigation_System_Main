import 'dart:math';
import 'package:flutter/material.dart';
import '../../../admin_map/domain/entities/map_entities.dart';

class PathArrowPainter extends CustomPainter {
  final List<Room> rooms;
  final List<String> pathIds;
  final double scale;

  PathArrowPainter({
    required this.rooms,
    required this.pathIds,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pathIds.length < 2) return;

    final paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final pathColor = Colors.blueAccent.withValues(alpha: 0.8);
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Map IDs to Rooms for O(1) lookup
    final roomMap = {for (var r in rooms) r.id: r};

    for (int i = 0; i < pathIds.length - 1; i++) {
      final currentId = pathIds[i];
      final nextId = pathIds[i + 1];

      final current = roomMap[currentId];
      final next = roomMap[nextId];

      if (current == null || next == null) continue;

      // Skip vertical connections (same x/y typically, or vastly different if building view,
      // but here we are usually on one floor. If cross-floor, one might be missing or at 0,0)
      // Check if they are on same floor implicitly by existence in roomMap (which comes from provider for THAT floor)
      // If next room is NOT in this floor's room list, we stop drawing line to it?
      // Actually UserHomeScreen loads rooms for ONE floor.
      // If the path goes off-floor, those IDs won't be in `roomMap`?
      // Wait, `rooms` comes from `roomsProvider(params)` which is for ONE floor.
      // So `pathIds` will contain IDs not in `rooms`.
      // reliable check: Only draw if BOTH are in `roomMap`.

      final p1 = Offset(current.x, current.y);
      final p2 = Offset(next.x, next.y);

      // Draw Line (Thick)
      canvas.drawLine(p1, p2, paint..strokeWidth = 4.0);

      // Draw Arrow in middle
      _drawArrow(canvas, p1, p2, pathColor);
    }
  }

  void _drawArrow(Canvas canvas, Offset p1, Offset p2, Color color) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance < 20) return; // Too short for arrow

    final angle = atan2(dy, dx);
    final midX = (p1.dx + p2.dx) / 2;
    final midY = (p1.dy + p2.dy) / 2;
    final mid = Offset(midX, midY);

    canvas.save();
    canvas.translate(midX, midY);
    canvas.rotate(angle);

    final path = Path();
    path.moveTo(-5, -5);
    path.lineTo(5, 0);
    path.lineTo(-5, 5);
    path.close();

    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PathArrowPainter oldDelegate) {
    return oldDelegate.pathIds != pathIds || oldDelegate.rooms != rooms;
  }
}
