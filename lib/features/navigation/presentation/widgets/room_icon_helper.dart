import 'package:flutter/material.dart';
import '../../../admin_map/domain/entities/map_entities.dart';

/// Returns the appropriate icon and color for a given [RoomType].
///
/// Used by both the admin map editor and user navigation views
/// to ensure consistent visual representation of node types.
({IconData icon, Color color, double size}) getRoomVisuals(RoomType type) {
  switch (type) {
    case RoomType.room:
      return (icon: Icons.meeting_room, color: Colors.blueAccent, size: 40);
    case RoomType.hallway:
      return (icon: Icons.circle, color: Colors.grey, size: 20);
    case RoomType.stairs:
      return (icon: Icons.stairs, color: Colors.green, size: 40);
    case RoomType.elevator:
      return (icon: Icons.elevator, color: Colors.purple, size: 40);
    case RoomType.entrance:
      return (icon: Icons.door_back_door, color: Colors.redAccent, size: 44);
    case RoomType.restroom:
      return (icon: Icons.wc, color: Colors.cyan, size: 40);
    case RoomType.cafeteria:
      return (icon: Icons.local_cafe, color: Colors.orange, size: 40);
    case RoomType.lab:
      return (icon: Icons.science, color: Colors.teal, size: 40);
    case RoomType.library:
      return (icon: Icons.local_library, color: Colors.brown, size: 40);
    case RoomType.parking:
      return (icon: Icons.local_parking, color: Colors.blueGrey, size: 44);
    case RoomType.ground:
      return (icon: Icons.grass, color: Colors.lightGreen, size: 44);
    case RoomType.office:
      return (icon: Icons.business, color: Colors.indigo, size: 40);
  }
}

/// Returns a human-readable label for a [RoomType].
String getRoomTypeLabel(RoomType type) {
  switch (type) {
    case RoomType.room:
      return 'Room';
    case RoomType.hallway:
      return 'Hallway';
    case RoomType.stairs:
      return 'Stairs';
    case RoomType.elevator:
      return 'Elevator';
    case RoomType.entrance:
      return 'Entrance';
    case RoomType.restroom:
      return 'Restroom';
    case RoomType.cafeteria:
      return 'Cafeteria';
    case RoomType.lab:
      return 'Lab';
    case RoomType.library:
      return 'Library';
    case RoomType.parking:
      return 'Parking';
    case RoomType.ground:
      return 'Ground';
    case RoomType.office:
      return 'Office';
  }
}
