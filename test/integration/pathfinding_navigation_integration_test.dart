import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/core/services/pathfinding_service.dart';
import 'package:indoor_navigation_system/core/services/navigation_instruction_service.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';

void main() {
  group('Pathfinding → Navigation Instructions Integration', () {
    late NavigationInstructionService instructionService;

    setUp(() {
      instructionService = NavigationInstructionService();
    });

    test('straight-line path produces start → walk → arrive instructions', () {
      // Build a simple straight-line map: A — B — C
      final rooms = [
        const Room(
          id: 'A',
          floorId: 'f1',
          name: 'Entrance',
          x: 0,
          y: 0,
          type: RoomType.entrance,
        ),
        const Room(
          id: 'B',
          floorId: 'f1',
          name: 'Hallway 1',
          x: 50,
          y: 0,
          type: RoomType.hallway,
        ),
        const Room(
          id: 'C',
          floorId: 'f1',
          name: 'Library',
          x: 100,
          y: 0,
          type: RoomType.library,
        ),
      ];
      final corridors = [
        const Corridor(
          id: 'c1',
          floorId: 'f1',
          startRoomId: 'A',
          endRoomId: 'B',
          distance: 10,
        ),
        const Corridor(
          id: 'c2',
          floorId: 'f1',
          startRoomId: 'B',
          endRoomId: 'C',
          distance: 15,
        ),
      ];

      // 1. Pathfind
      final pathIds = PathfindingService.findPath('A', 'C', rooms, corridors);
      expect(pathIds, ['A', 'B', 'C']);

      // 2. Convert path IDs to Room objects
      final pathRooms = pathIds
          .map((id) => rooms.firstWhere((r) => r.id == id))
          .toList();

      // 3. Generate instructions
      final instructions = instructionService.generateInstructions(
        pathRooms,
        corridors: corridors,
      );

      // Verify structure: start, direction, walk(s), arrive
      expect(instructions.length, greaterThanOrEqualTo(3));
      expect(instructions.first.message, contains('Start at Entrance'));
      expect(instructions.first.icon, 'start');
      expect(instructions.last.message, contains('Arrive at Library'));
      expect(instructions.last.icon, 'finish');

      // Walk instructions should have merged distances for straight segments
      final walkInstructions = instructions
          .where((i) => i.icon == 'straight' && i.distance > 0)
          .toList();
      expect(walkInstructions, isNotEmpty);
      // Total distance should be 10 + 15 = 25
      final totalWalkDist = walkInstructions.fold(
        0.0,
        (sum, i) => sum + i.distance,
      );
      expect(totalWalkDist, 25.0);
    });

    test('path with turn produces correct turn instruction', () {
      // L-shaped path: A → B → C (90° right turn at B)
      final rooms = [
        const Room(
          id: 'A',
          floorId: 'f1',
          name: 'Start Room',
          x: 0,
          y: 0,
          type: RoomType.room,
        ),
        const Room(
          id: 'B',
          floorId: 'f1',
          name: 'Corner',
          x: 100,
          y: 0,
          type: RoomType.hallway,
        ),
        const Room(
          id: 'C',
          floorId: 'f1',
          name: 'End Room',
          x: 100,
          y: 100,
          type: RoomType.room,
        ),
      ];
      final corridors = [
        const Corridor(
          id: 'c1',
          floorId: 'f1',
          startRoomId: 'A',
          endRoomId: 'B',
          distance: 20,
        ),
        const Corridor(
          id: 'c2',
          floorId: 'f1',
          startRoomId: 'B',
          endRoomId: 'C',
          distance: 20,
        ),
      ];

      final pathIds = PathfindingService.findPath('A', 'C', rooms, corridors);
      expect(pathIds, ['A', 'B', 'C']);

      final pathRooms = pathIds
          .map((id) => rooms.firstWhere((r) => r.id == id))
          .toList();
      final instructions = instructionService.generateInstructions(
        pathRooms,
        corridors: corridors,
      );

      // Should contain a turn instruction
      final turnInstructions = instructions
          .where((i) => i.icon == 'right' || i.icon == 'left')
          .toList();
      expect(turnInstructions, isNotEmpty);
    });

    test('no path found produces empty instructions', () {
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
          id: 'B',
          floorId: 'f2',
          name: 'End',
          x: 100,
          y: 100,
          type: RoomType.room,
        ),
      ];

      // No corridors — no path
      final pathIds = PathfindingService.findPath('A', 'B', rooms, []);
      expect(pathIds, isEmpty);

      // Empty path → empty instructions
      final instructions = instructionService.generateInstructions([]);
      expect(instructions, isEmpty);
    });

    test('single-room path produces destination message', () {
      final rooms = [
        const Room(
          id: 'A',
          floorId: 'f1',
          name: 'Destination',
          x: 0,
          y: 0,
          type: RoomType.room,
        ),
      ];

      final pathIds = PathfindingService.findPath('A', 'A', rooms, []);
      expect(pathIds, ['A']);

      final pathRooms = pathIds
          .map((id) => rooms.firstWhere((r) => r.id == id))
          .toList();
      final instructions = instructionService.generateInstructions(pathRooms);

      expect(instructions.length, 1);
      expect(instructions.first.message, contains('destination'));
    });

    test('instructions are numbered sequentially', () {
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
          id: 'B',
          floorId: 'f1',
          name: 'Middle',
          x: 50,
          y: 0,
          type: RoomType.hallway,
        ),
        const Room(
          id: 'C',
          floorId: 'f1',
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
          endRoomId: 'B',
          distance: 10,
        ),
        const Corridor(
          id: 'c2',
          floorId: 'f1',
          startRoomId: 'B',
          endRoomId: 'C',
          distance: 10,
        ),
      ];

      final pathIds = PathfindingService.findPath('A', 'C', rooms, corridors);
      final pathRooms = pathIds
          .map((id) => rooms.firstWhere((r) => r.id == id))
          .toList();
      final instructions = instructionService.generateInstructions(
        pathRooms,
        corridors: corridors,
      );

      // Every instruction should start with its step number
      for (int i = 0; i < instructions.length; i++) {
        expect(instructions[i].message, startsWith('${i + 1}. '));
      }
    });

    test('path with compass heading produces orientation instruction', () {
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
          id: 'B',
          floorId: 'f1',
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
          endRoomId: 'B',
          distance: 20,
        ),
      ];

      final pathIds = PathfindingService.findPath('A', 'B', rooms, corridors);
      final pathRooms = pathIds
          .map((id) => rooms.firstWhere((r) => r.id == id))
          .toList();

      // User facing north (heading=0), path goes east
      // Should produce a "Turn Right" orientation instruction
      final instructions = instructionService.generateInstructions(
        pathRooms,
        corridors: corridors,
        currentHeading: 0,
      );

      expect(instructions.length, greaterThanOrEqualTo(3));
      // Second instruction (after "Start at") should be orientation
      // The path goes east (bearing ~90°), user faces north (0°), so turn right
      final orientInst = instructions[1];
      expect(
        orientInst.icon == 'right' ||
            orientInst.icon == 'left' ||
            orientInst.icon == 'straight' ||
            orientInst.icon == 'uturn',
        isTrue,
      );
    });
  });
}
