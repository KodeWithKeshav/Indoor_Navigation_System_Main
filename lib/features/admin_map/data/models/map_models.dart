import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/map_entities.dart';

class BuildingModel extends Building {
  const BuildingModel({
    required super.id,
    required super.name,
    required super.description,
    super.organizationId,
    super.northOffset,
  });

  factory BuildingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BuildingModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      organizationId: data['organizationId'],
      northOffset: (data['northOffset'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'organizationId': organizationId,
      'northOffset': northOffset,
    };
  }
}

class FloorModel extends Floor {
  const FloorModel({
    required super.id,
    required super.buildingId,
    required super.floorNumber,
    required super.name,
  });

  factory FloorModel.fromFirestore(DocumentSnapshot doc, String buildingId) {
    final data = doc.data() as Map<String, dynamic>;
    return FloorModel(
      id: doc.id,
      buildingId: buildingId,
      floorNumber: data['floorNumber'] ?? 0,
      name: data['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'floorNumber': floorNumber,
      'name': name,
    };
  }
}

class RoomModel extends Room {
  const RoomModel({
    required super.id,
    required super.floorId,
    required super.name,
    required super.x,
    required super.y,
    super.type,
    super.connectorId,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc, String floorId) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      id: doc.id,
      floorId: floorId,
      name: data['name'] ?? '',
      x: (data['x'] as num?)?.toDouble() ?? 0.0,
      y: (data['y'] as num?)?.toDouble() ?? 0.0,
      type: RoomType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'room'),
        orElse: () => RoomType.room,
      ),
      connectorId: data['connectorId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'x': x,
      'y': y,
      'type': type.name,
      'connectorId': connectorId,
    };
  }
}

class CorridorModel extends Corridor {
  const CorridorModel({
    required super.id,
    required super.floorId,
    required super.startRoomId,
    required super.endRoomId,
    required super.distance,
  });

  factory CorridorModel.fromFirestore(DocumentSnapshot doc, String floorId) {
    final data = doc.data() as Map<String, dynamic>;
    return CorridorModel(
      id: doc.id,
      floorId: floorId,
      startRoomId: data['startRoomId'] ?? '',
      endRoomId: data['endRoomId'] ?? '',
      distance: (data['distance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startRoomId': startRoomId,
      'endRoomId': endRoomId,
      'distance': distance,
    };
  }
}
