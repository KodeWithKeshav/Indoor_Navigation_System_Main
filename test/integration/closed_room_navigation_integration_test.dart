import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/core/services/pathfinding_service.dart';
import 'package:indoor_navigation_system/core/services/navigation_instruction_service.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';

void main() {
  group('Closed Room Navigation Integration', () {
    late NavigationInstructionService instructionService;

    // Graph layout:
    //   A --- B --- C
    //   |           |
    //   D --------- E
    //
    // Normal shortest A→C is A-B-C (20).
    // When B is closed, reroute: A-D-E-C (40).
    late List<Room> rooms;
    late List<Corridor> corridors;

    setUp(() {
      instructionService = NavigationInstructionService();

      rooms = [
        const Room(
          id: 'A',
          floorId: 'f1',
          name: 'Room A',
          x: 0,
          y: 0,
          type: RoomType.room,
        ),
        const Room(
          id: 'B',
          floorId: 'f1',
          name: 'Room B',
          x: 50,
          y: 0,
          type: RoomType.hallway,
        ),
        const Room(
          id: 'C',
          floorId: 'f1',
          name: 'Room C',
          x: 100,
          y: 0,
          type: RoomType.room,
        ),
        const Room(
          id: 'D',
          floorId: 'f1',
          name: 'Room D',
          x: 0,
          y: 50,
          type: RoomType.room,
        ),
        const Room(
          id: 'E',
          floorId: 'f1',
          name: 'Room E',
          x: 100,
          y: 50,
          type: RoomType.room,
        ),
      ];

      corridors = [
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
        const Corridor(
          id: 'c3',
          floorId: 'f1',
          startRoomId: 'A',
          endRoomId: 'D',
          distance: 10,
        ),
        const Corridor(
          id: 'c4',
          floorId: 'f1',
          startRoomId: 'D',
          endRoomId: 'E',
          distance: 20,
        ),
        const Corridor(
          id: 'c5',
          floorId: 'f1',
          startRoomId: 'C',
          endRoomId: 'E',
          distance: 10,
        ),
      ];
    });

    test('normal path goes through B when not closed', () {
      final path = PathfindingService.findPath('A', 'C', rooms, corridors);
      expect(path, ['A', 'B', 'C']);
    });

    test('path reroutes around closed room B', () {
      // Close room B
      final closedRooms = List<Room>.from(rooms);
      closedRooms[1] = const Room(
        id: 'B',
        floorId: 'f1',
        name: 'Room B',
        x: 50,
        y: 0,
        type: RoomType.hallway,
        isClosed: true,
      );

      final path = PathfindingService.findPath(
        'A',
        'C',
        closedRooms,
        corridors,
      );
      expect(path, ['A', 'D', 'E', 'C']);

      // Generate instructions from the rerouted path
      final pathRooms = path
          .map((id) => closedRooms.firstWhere((r) => r.id == id))
          .toList();
      final instructions = instructionService.generateInstructions(
        pathRooms,
        corridors: corridors,
      );

      // Instructions should NOT reference Room B
      for (final inst in instructions) {
        expect(inst.message, isNot(contains('Room B')));
      }

      // Should have start and finish
      expect(instructions.first.message, contains('Start at Room A'));
      expect(instructions.last.message, contains('Arrive at Room C'));
    });

    test('closed destination returns empty path', () {
      // Close room C (destination)
      final closedRooms = List<Room>.from(rooms);
      closedRooms[2] = const Room(
        id: 'C',
        floorId: 'f1',
        name: 'Room C',
        x: 100,
        y: 0,
        type: RoomType.room,
        isClosed: true,
      );

      final path = PathfindingService.findPath(
        'A',
        'C',
        closedRooms,
        corridors,
      );
      expect(path, isEmpty);
    });

    test('multiple closed rooms force longer alternative', () {
      // Close both B and D — only path is impossible
      final closedRooms = List<Room>.from(rooms);
      closedRooms[1] = const Room(
        id: 'B',
        floorId: 'f1',
        name: 'Room B',
        x: 50,
        y: 0,
        type: RoomType.hallway,
        isClosed: true,
      );
      closedRooms[3] = const Room(
        id: 'D',
        floorId: 'f1',
        name: 'Room D',
        x: 0,
        y: 50,
        type: RoomType.room,
        isClosed: true,
      );

      // A has no open neighbors except via B and D, both closed
      final path = PathfindingService.findPath(
        'A',
        'C',
        closedRooms,
        corridors,
      );
      expect(path, isEmpty);
    });

    test('closing and reopening a room restores original path', () {
      // Close B → reroute
      final closedRooms = List<Room>.from(rooms);
      closedRooms[1] = const Room(
        id: 'B',
        floorId: 'f1',
        name: 'Room B',
        x: 50,
        y: 0,
        type: RoomType.hallway,
        isClosed: true,
      );
      final reroutedPath = PathfindingService.findPath(
        'A',
        'C',
        closedRooms,
        corridors,
      );
      expect(reroutedPath, ['A', 'D', 'E', 'C']);

      // Reopen B → original path
      closedRooms[1] = const Room(
        id: 'B',
        floorId: 'f1',
        name: 'Room B',
        x: 50,
        y: 0,
        type: RoomType.hallway,
        isClosed: false,
      );
      final reopenedPath = PathfindingService.findPath(
        'A',
        'C',
        closedRooms,
        corridors,
      );
      expect(reopenedPath, ['A', 'B', 'C']);
    });
  });
}
