import 'package:flutter/material.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'room_icon_helper.dart';

class UserEdgePainter extends CustomPainter {
  final List<Room> rooms;
  final List<Corridor> corridors;
  final List<String> pathIds;

  UserEdgePainter({
    required this.rooms,
    required this.corridors,
    this.pathIds = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rooms.isEmpty) return;

    // Create a map for fast lookup
    final roomMap = {for (var r in rooms) r.id: r};

    final paint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.4) // faint electricGrid
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pathPaint = Paint()
      ..color = Colors.amber // Amber for path (matches node highlight)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final corridor in corridors) {
      final startRoom = roomMap[corridor.startRoomId];
      final endRoom = roomMap[corridor.endRoomId];

      if (startRoom != null && endRoom != null) {
        // Determine if this corridor is part of the path
        bool isPathEdge = false;
        if (pathIds.length > 1) {
           // Check if this corridor connects two consecutive nodes in the path
           for (int i = 0; i < pathIds.length - 1; i++) {
              final a = pathIds[i];
              final b = pathIds[i+1];
              if ((corridor.startRoomId == a && corridor.endRoomId == b) || 
                  (corridor.startRoomId == b && corridor.endRoomId == a)) {
                 isPathEdge = true;
                 break;
              }
           }
        }

        final drawPaint = isPathEdge ? pathPaint : paint;
        
        // Calculate dynamic centers based on room type visuals
        final startCenter = _getRoomCenter(startRoom, pathIds.contains(startRoom.id));
        final endCenter = _getRoomCenter(endRoom, pathIds.contains(endRoom.id));

        canvas.drawLine(startCenter, endCenter, drawPaint);
      }
    }
  }

  Offset _getRoomCenter(Room room, bool isInPath) {
    // Logic matching _MapViewer's rendering
    double nodeSize;
    if (room.type == RoomType.hallway) {
        // Hallway nodes are 20.0 if in path, otherwise effectively 0/invisible (but we map them anyway)
        // If not in path, _MapViewer hides them. But we might still draw edges connecting them?
        // Usually edges connect visible nodes. 
        // If the path goes through them, they are size 20.
        nodeSize = isInPath ? 20.0 : 20.0; // Assume 20 for center calculation
    } else {
        nodeSize = getRoomVisuals(room.type).size.toDouble();
    }
    
    // Positioned(left: x, top: y) -> Center is x + size/2
    return Offset(room.x + nodeSize / 2, room.y + nodeSize / 2);
  }

  @override
  bool shouldRepaint(covariant UserEdgePainter oldDelegate) {
     return oldDelegate.corridors != corridors || 
            oldDelegate.rooms != rooms || 
            oldDelegate.pathIds != pathIds;
  }
}
