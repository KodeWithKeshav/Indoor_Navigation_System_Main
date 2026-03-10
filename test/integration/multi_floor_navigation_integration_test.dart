import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/core/services/pathfinding_service.dart';
import 'package:indoor_navigation_system/core/services/navigation_instruction_service.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';

void main() {
  group('Multi-Floor Navigation Integration', () {
    late NavigationInstructionService instructionService;

    setUp(() {
      instructionService = NavigationInstructionService();
    });

    test('path through stairs produces stairs up/down instruction', () {
      // Floor 1: A — StairsF1
      // Floor 2: StairsF2 — B
      // Vertical: StairsF1 ↔ StairsF2 (same connectorId)
      final rooms = [
        const Room(
          id: 'A',
          floorId: 'f1',
          name: 'Room A',
          x: 0,
          y: 0,
          type: RoomType.room,
        ),
        const Room(
          id: 'StairsF1',
          floorId: 'f1',
          name: 'Stairs',
          x: 50,
          y: 0,
          type: RoomType.stairs,
          connectorId: 'stair-1',
        ),
        const Room(
          id: 'StairsF2',
          floorId: 'f2',
          name: 'Stairs',
          x: 50,
          y: 0,
          type: RoomType.stairs,
          connectorId: 'stair-1',
        ),
        const Room(
          id: 'B',
          floorId: 'f2',
          name: 'Room B',
          x: 100,
          y: 0,
          type: RoomType.room,
        ),
      ];
      final corridors = [
        const Corridor(
          id: 'c1',
          floorId: 'f1',
          startRoomId: 'A',
          endRoomId: 'StairsF1',
          distance: 10,
        ),
        const Corridor(
          id: 'c2',
          floorId: 'vertical',
          startRoomId: 'StairsF1',
          endRoomId: 'StairsF2',
          distance: 5,
        ),
        const Corridor(
          id: 'c3',
          floorId: 'f2',
          startRoomId: 'StairsF2',
          endRoomId: 'B',
          distance: 10,
        ),
      ];

      final pathIds = PathfindingService.findPath('A', 'B', rooms, corridors);
      expect(pathIds, isNotEmpty);
      expect(pathIds.first, 'A');
      expect(pathIds.last, 'B');

      final pathRooms = pathIds
          .map((id) => rooms.firstWhere((r) => r.id == id))
          .toList();
      final floorLevels = {'f1': 1, 'f2': 2};

      final instructions = instructionService.generateInstructions(
        pathRooms,
        corridors: corridors,
        floorLevels: floorLevels,
      );

      // Should contain "Take stairs up" instruction
      final stairsInstructions = instructions
          .where((i) => i.icon == 'stairs_up' || i.icon == 'stairs_down')
          .toList();
      expect(stairsInstructions, isNotEmpty);
      expect(stairsInstructions.first.icon, 'stairs_up');
      expect(stairsInstructions.first.message, contains('stairs'));

      // Start and finish
      expect(instructions.first.message, contains('Start at Room A'));
      expect(instructions.last.message, contains('Arrive at Room B'));
    });

    test('accessible mode avoids stairs and uses elevator', () {
      // Two vertical options: stairs (shorter) and elevator (longer)
      final rooms = [
        const Room(
          id: 'A',
          floorId: 'f1',
          name: 'Start',
          x: 0,
          y: 0,
          type: RoomType.room,
        ),
        const Room(
          id: 'Hall',
          floorId: 'f1',
          name: 'Hall',
          x: 25,
          y: 0,
          type: RoomType.hallway,
        ),
        const Room(
          id: 'StairsF1',
          floorId: 'f1',
          name: 'Stairs',
          x: 50,
          y: 10,
          type: RoomType.stairs,
          connectorId: 'stair-1',
        ),
        const Room(
          id: 'ElevF1',
          floorId: 'f1',
          name: 'Elevator',
          x: 50,
          y: -10,
          type: RoomType.elevator,
          connectorId: 'elev-1',
        ),
        const Room(
          id: 'StairsF2',
          floorId: 'f2',
          name: 'Stairs',
          x: 50,
          y: 10,
          type: RoomType.stairs,
          connectorId: 'stair-1',
        ),
        const Room(
          id: 'ElevF2',
          floorId: 'f2',
          name: 'Elevator',
          x: 50,
          y: -10,
          type: RoomType.elevator,
          connectorId: 'elev-1',
        ),
        const Room(
          id: 'B',
          floorId: 'f2',
          name: 'End',
          x: 100,
          y: 0,
          type: RoomType.room,
        ),
      ];
      final corridors = [
        const Corridor(
          id: 'c1',
          floorId: 'f1',
          startRoomId: 'A',
          endRoomId: 'Hall',
          distance: 5,
        ),
        const Corridor(
          id: 'c2',
          floorId: 'f1',
          startRoomId: 'Hall',
          endRoomId: 'StairsF1',
          distance: 5,
        ),
        const Corridor(
          id: 'c3',
          floorId: 'f1',
          startRoomId: 'Hall',
          endRoomId: 'ElevF1',
          distance: 5,
        ),
        const Corridor(
          id: 'c4',
          floorId: 'vertical',
          startRoomId: 'StairsF1',
          endRoomId: 'StairsF2',
          distance: 5,
        ),
        const Corridor(
          id: 'c5',
          floorId: 'vertical',
          startRoomId: 'ElevF1',
          endRoomId: 'ElevF2',
          distance: 10,
        ),
        const Corridor(
          id: 'c6',
          floorId: 'f2',
          startRoomId: 'StairsF2',
          endRoomId: 'B',
          distance: 10,
        ),
        const Corridor(
          id: 'c7',
          floorId: 'f2',
          startRoomId: 'ElevF2',
          endRoomId: 'B',
          distance: 10,
        ),
      ];

      // Without accessibility — should use stairs (shorter)
      final normalPath = PathfindingService.findPath(
        'A',
        'B',
        rooms,
        corridors,
        isAccessible: false,
      );
      expect(normalPath, contains('StairsF1'));

      // With accessibility — should use elevator
      final accessiblePath = PathfindingService.findPath(
        'A',
        'B',
        rooms,
        corridors,
        isAccessible: true,
      );
      expect(accessiblePath, contains('ElevF1'));
      expect(accessiblePath, isNot(contains('StairsF1')));

      // Generate instructions for accessible path
      final pathRooms = accessiblePath
          .map((id) => rooms.firstWhere((r) => r.id == id))
          .toList();
      final floorLevels = {'f1': 1, 'f2': 2};

      final instructions = instructionService.generateInstructions(
        pathRooms,
        corridors: corridors,
        floorLevels: floorLevels,
      );

      // Should have elevator instruction, not stairs
      final elevatorInstructions = instructions
          .where((i) => i.icon == 'elevator_up' || i.icon == 'elevator_down')
          .toList();
      expect(elevatorInstructions, isNotEmpty);
      expect(elevatorInstructions.first.message, contains('elevator'));

      final stairsInstructions = instructions
          .where((i) => i.icon == 'stairs_up' || i.icon == 'stairs_down')
          .toList();
      expect(stairsInstructions, isEmpty);
    });

    test('accessible mode with no elevator returns empty path', () {
      // Only stairs available
      final rooms = [
        const Room(
          id: 'A',
          floorId: 'f1',
          name: 'Start',
          x: 0,
          y: 0,
          type: RoomType.room,
        ),
        const Room(
          id: 'StairsF1',
          floorId: 'f1',
          name: 'Stairs',
          x: 50,
          y: 0,
          type: RoomType.stairs,
          connectorId: 'stair-1',
        ),
        const Room(
          id: 'StairsF2',
          floorId: 'f2',
          name: 'Stairs',
          x: 50,
          y: 0,
          type: RoomType.stairs,
          connectorId: 'stair-1',
        ),
        const Room(
          id: 'B',
          floorId: 'f2',
          name: 'End',
          x: 100,
          y: 0,
          type: RoomType.room,
        ),
      ];
      final corridors = [
        const Corridor(
          id: 'c1',
          floorId: 'f1',
          startRoomId: 'A',
          endRoomId: 'StairsF1',
          distance: 10,
        ),
        const Corridor(
          id: 'c2',
          floorId: 'vertical',
          startRoomId: 'StairsF1',
          endRoomId: 'StairsF2',
          distance: 5,
        ),
        const Corridor(
          id: 'c3',
          floorId: 'f2',
          startRoomId: 'StairsF2',
          endRoomId: 'B',
          distance: 10,
        ),
      ];

      final path = PathfindingService.findPath(
        'A',
        'B',
        rooms,
        corridors,
        isAccessible: true,
      );
      expect(path, isEmpty);
    });

    test('going down floors produces stairs_down instruction', () {
      // Start on floor 2, go down to floor 1
      final rooms = [
        const Room(
          id: 'A',
          floorId: 'f2',
          name: 'Room A',
          x: 0,
          y: 0,
          type: RoomType.room,
        ),
        const Room(
          id: 'StairsF2',
          floorId: 'f2',
          name: 'Stairs',
          x: 50,
          y: 0,
          type: RoomType.stairs,
          connectorId: 'stair-1',
        ),
        const Room(
          id: 'StairsF1',
          floorId: 'f1',
          name: 'Stairs',
          x: 50,
          y: 0,
          type: RoomType.stairs,
          connectorId: 'stair-1',
        ),
        const Room(
          id: 'B',
          floorId: 'f1',
          name: 'Room B',
          x: 100,
          y: 0,
          type: RoomType.room,
        ),
      ];
      final corridors = [
        const Corridor(
          id: 'c1',
          floorId: 'f2',
          startRoomId: 'A',
          endRoomId: 'StairsF2',
          distance: 10,
        ),
        const Corridor(
          id: 'c2',
          floorId: 'vertical',
          startRoomId: 'StairsF2',
          endRoomId: 'StairsF1',
          distance: 5,
        ),
        const Corridor(
          id: 'c3',
          floorId: 'f1',
          startRoomId: 'StairsF1',
          endRoomId: 'B',
          distance: 10,
        ),
      ];

      final pathIds = PathfindingService.findPath('A', 'B', rooms, corridors);
      final pathRooms = pathIds
          .map((id) => rooms.firstWhere((r) => r.id == id))
          .toList();
      final floorLevels = {'f1': 1, 'f2': 2};

      final instructions = instructionService.generateInstructions(
        pathRooms,
        corridors: corridors,
        floorLevels: floorLevels,
      );

      final stairsDownInst = instructions
          .where((i) => i.icon == 'stairs_down')
          .toList();
      expect(stairsDownInst, isNotEmpty);
      expect(stairsDownInst.first.message, contains('stairs'));
      expect(stairsDownInst.first.message, contains('down'));
    });
  });
}
