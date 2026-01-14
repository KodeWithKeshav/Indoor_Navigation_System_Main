import 'package:equatable/equatable.dart';
export 'organization.dart';
export 'campus_entities.dart';

class Building extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? organizationId;
  final double northOffset; // Angle in degrees where map "Up" is relative to North

  const Building({
    required this.id,
    required this.name,
    required this.description,
    this.organizationId,
    this.northOffset = 0.0,
  });

  @override
  List<Object?> get props => [id, name, description, organizationId, northOffset];
}

class Floor extends Equatable {
  final String id;
  final String buildingId;
  final int floorNumber;
  final String name;

  const Floor({
    required this.id,
    required this.buildingId,
    required this.floorNumber,
    required this.name,
  });

  @override
  List<Object> get props => [id, buildingId, floorNumber, name];
}

enum RoomType {
  room,       // Generic Classroom/Room
  hallway,    // Navigation node
  stairs,     // Vertical
  elevator,   // Vertical
  entrance,   // Building Connector
  restroom,   // WC
  cafeteria,  // Food
  lab,        // Laboratory
  library,    // Library building or room
  parking,    // Parking Lot
  ground,     // Sports ground / Open area
  office,     // Admin/Faculty office
}

class Room extends Equatable {
  final String id;
  final String floorId;
  final String name;
  final double x; // Coordinate X
  final double y; // Coordinate Y
  final RoomType type;
  final String? connectorId; // For linking vertical nodes (e.g. "Stair A")

  const Room({
    required this.id,
    required this.floorId,
    required this.name,
    required this.x,
    required this.y,
    this.type = RoomType.room,
    this.connectorId,
  });

  @override
  List<Object?> get props => [id, floorId, name, x, y, type, connectorId];
}

class Corridor extends Equatable {
  final String id;
  final String floorId;
  final String startRoomId;
  final String endRoomId;
  final double distance;

  const Corridor({
    required this.id,
    required this.floorId,
    required this.startRoomId,
    required this.endRoomId,
    required this.distance,
  });

  @override
  List<Object> get props => [id, floorId, startRoomId, endRoomId, distance];
}
