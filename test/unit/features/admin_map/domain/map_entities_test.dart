import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';

void main() {
  group('Building Entity', () {
    test('should create Building with required parameters', () {
      const building = Building(
        id: 'bld-1',
        name: 'Main Building',
        description: 'The main campus building',
      );

      expect(building.id, 'bld-1');
      expect(building.name, 'Main Building');
      expect(building.description, 'The main campus building');
      expect(building.organizationId, isNull);
    });

    test('should create Building with organization ID', () {
      const building = Building(
        id: 'bld-1',
        name: 'Main Building',
        description: 'The main campus building',
        organizationId: 'org-123',
      );

      expect(building.organizationId, 'org-123');
    });

    test('should be equal when all properties match', () {
      const building1 = Building(
        id: 'bld-1',
        name: 'Main Building',
        description: 'Description',
      );
      const building2 = Building(
        id: 'bld-1',
        name: 'Main Building',
        description: 'Description',
      );

      expect(building1, equals(building2));
    });

    test('should not be equal when properties differ', () {
      const building1 = Building(
        id: 'bld-1',
        name: 'Main Building',
        description: 'Description',
      );
      const building2 = Building(
        id: 'bld-2',
        name: 'Other Building',
        description: 'Description',
      );

      expect(building1, isNot(equals(building2)));
    });
  });

  group('Floor Entity', () {
    test('should create Floor with required parameters', () {
      const floor = Floor(
        id: 'floor-1',
        buildingId: 'bld-1',
        floorNumber: 1,
        name: 'First Floor',
      );

      expect(floor.id, 'floor-1');
      expect(floor.buildingId, 'bld-1');
      expect(floor.floorNumber, 1);
      expect(floor.name, 'First Floor');
    });

    test('should handle ground floor (floor number 0)', () {
      const floor = Floor(
        id: 'floor-g',
        buildingId: 'bld-1',
        floorNumber: 0,
        name: 'Ground Floor',
      );

      expect(floor.floorNumber, 0);
    });

    test('should handle basement (negative floor number)', () {
      const floor = Floor(
        id: 'floor-b1',
        buildingId: 'bld-1',
        floorNumber: -1,
        name: 'Basement 1',
      );

      expect(floor.floorNumber, -1);
    });

    test('should be equal when all properties match', () {
      const floor1 = Floor(
        id: 'f1',
        buildingId: 'b1',
        floorNumber: 1,
        name: 'F1',
      );
      const floor2 = Floor(
        id: 'f1',
        buildingId: 'b1',
        floorNumber: 1,
        name: 'F1',
      );

      expect(floor1, equals(floor2));
    });
  });

  group('Room Entity', () {
    test('should create Room with required parameters', () {
      const room = Room(
        id: 'room-1',
        floorId: 'floor-1',
        name: 'Classroom 101',
        x: 10.5,
        y: 20.3,
      );

      expect(room.id, 'room-1');
      expect(room.floorId, 'floor-1');
      expect(room.name, 'Classroom 101');
      expect(room.x, 10.5);
      expect(room.y, 20.3);
      expect(room.type, RoomType.room); // Default type
      expect(room.connectorId, isNull);
    });

    test('should create Room with custom type', () {
      const room = Room(
        id: 'room-1',
        floorId: 'floor-1',
        name: 'Main Entrance',
        x: 0,
        y: 0,
        type: RoomType.entrance,
      );

      expect(room.type, RoomType.entrance);
    });

    test('should create Room with connector ID for vertical connections', () {
      const room = Room(
        id: 'stair-f1',
        floorId: 'floor-1',
        name: 'Staircase A',
        x: 50,
        y: 50,
        type: RoomType.stairs,
        connectorId: 'stair-a',
      );

      expect(room.connectorId, 'stair-a');
      expect(room.type, RoomType.stairs);
    });

    test('should handle negative coordinates', () {
      const room = Room(
        id: 'room-1',
        floorId: 'floor-1',
        name: 'Room',
        x: -10.5,
        y: -20.3,
      );

      expect(room.x, -10.5);
      expect(room.y, -20.3);
    });

    test('should be equal when all properties match', () {
      const room1 = Room(id: 'r1', floorId: 'f1', name: 'R', x: 0, y: 0);
      const room2 = Room(id: 'r1', floorId: 'f1', name: 'R', x: 0, y: 0);

      expect(room1, equals(room2));
    });

    test('should not be equal when connectorId differs', () {
      const room1 = Room(
        id: 'r1',
        floorId: 'f1',
        name: 'R',
        x: 0,
        y: 0,
        connectorId: 'a',
      );
      const room2 = Room(
        id: 'r1',
        floorId: 'f1',
        name: 'R',
        x: 0,
        y: 0,
        connectorId: 'b',
      );

      expect(room1, isNot(equals(room2)));
    });
  });

  group('Corridor Entity', () {
    test('should create Corridor with required parameters', () {
      const corridor = Corridor(
        id: 'cor-1',
        floorId: 'floor-1',
        startRoomId: 'room-1',
        endRoomId: 'room-2',
        distance: 15.5,
      );

      expect(corridor.id, 'cor-1');
      expect(corridor.floorId, 'floor-1');
      expect(corridor.startRoomId, 'room-1');
      expect(corridor.endRoomId, 'room-2');
      expect(corridor.distance, 15.5);
    });

    test('should handle zero distance', () {
      const corridor = Corridor(
        id: 'cor-1',
        floorId: 'floor-1',
        startRoomId: 'room-1',
        endRoomId: 'room-2',
        distance: 0,
      );

      expect(corridor.distance, 0);
    });

    test('should handle large distance', () {
      const corridor = Corridor(
        id: 'cor-1',
        floorId: 'floor-1',
        startRoomId: 'room-1',
        endRoomId: 'room-2',
        distance: 10000.0,
      );

      expect(corridor.distance, 10000.0);
    });

    test('should be equal when all properties match', () {
      const cor1 = Corridor(
        id: 'c1',
        floorId: 'f1',
        startRoomId: 'r1',
        endRoomId: 'r2',
        distance: 10,
      );
      const cor2 = Corridor(
        id: 'c1',
        floorId: 'f1',
        startRoomId: 'r1',
        endRoomId: 'r2',
        distance: 10,
      );

      expect(cor1, equals(cor2));
    });

    test('should not be equal when distance differs', () {
      const cor1 = Corridor(
        id: 'c1',
        floorId: 'f1',
        startRoomId: 'r1',
        endRoomId: 'r2',
        distance: 10,
      );
      const cor2 = Corridor(
        id: 'c1',
        floorId: 'f1',
        startRoomId: 'r1',
        endRoomId: 'r2',
        distance: 20,
      );

      expect(cor1, isNot(equals(cor2)));
    });
  });

  group('RoomType Enum', () {
    test('should have all expected room types', () {
      expect(RoomType.values, contains(RoomType.room));
      expect(RoomType.values, contains(RoomType.hallway));
      expect(RoomType.values, contains(RoomType.stairs));
      expect(RoomType.values, contains(RoomType.elevator));
      expect(RoomType.values, contains(RoomType.entrance));
      expect(RoomType.values, contains(RoomType.restroom));
      expect(RoomType.values, contains(RoomType.cafeteria));
      expect(RoomType.values, contains(RoomType.lab));
      expect(RoomType.values, contains(RoomType.library));
      expect(RoomType.values, contains(RoomType.parking));
      expect(RoomType.values, contains(RoomType.ground));
      expect(RoomType.values, contains(RoomType.office));
    });

    test('should have correct number of room types', () {
      expect(RoomType.values.length, 12);
    });
  });
}
