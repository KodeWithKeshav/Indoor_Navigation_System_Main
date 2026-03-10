import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/core/services/pathfinding_service.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';

void main() {
  group('PathfindingService', () {
    // Test fixtures - reusable rooms and corridors
    late List<Room> rooms;
    late List<Corridor> corridors;

    setUp(() {
      // Create a simple graph:
      //   A --- B --- C
      //   |           |
      //   D --------- E
      rooms = [
        const Room(
          id: 'A',
          floorId: 'floor1',
          name: 'Room A',
          x: 0,
          y: 0,
          type: RoomType.room,
        ),
        const Room(
          id: 'B',
          floorId: 'floor1',
          name: 'Room B',
          x: 10,
          y: 0,
          type: RoomType.hallway,
        ),
        const Room(
          id: 'C',
          floorId: 'floor1',
          name: 'Room C',
          x: 20,
          y: 0,
          type: RoomType.room,
        ),
        const Room(
          id: 'D',
          floorId: 'floor1',
          name: 'Room D',
          x: 0,
          y: 10,
          type: RoomType.room,
        ),
        const Room(
          id: 'E',
          floorId: 'floor1',
          name: 'Room E',
          x: 20,
          y: 10,
          type: RoomType.room,
        ),
      ];

      corridors = [
        const Corridor(
          id: 'c1',
          floorId: 'floor1',
          startRoomId: 'A',
          endRoomId: 'B',
          distance: 10,
        ),
        const Corridor(
          id: 'c2',
          floorId: 'floor1',
          startRoomId: 'B',
          endRoomId: 'C',
          distance: 10,
        ),
        const Corridor(
          id: 'c3',
          floorId: 'floor1',
          startRoomId: 'A',
          endRoomId: 'D',
          distance: 10,
        ),
        const Corridor(
          id: 'c4',
          floorId: 'floor1',
          startRoomId: 'D',
          endRoomId: 'E',
          distance: 20,
        ),
        const Corridor(
          id: 'c5',
          floorId: 'floor1',
          startRoomId: 'C',
          endRoomId: 'E',
          distance: 10,
        ),
      ];
    });

    group('findPath', () {
      test('should find direct path between adjacent rooms', () {
        final path = PathfindingService.findPath('A', 'B', rooms, corridors);

        expect(path, isNotEmpty);
        expect(path.first, 'A');
        expect(path.last, 'B');
        expect(path.length, 2);
      });

      test('should find shortest path through multiple rooms', () {
        // A -> C shortest is A-B-C (20 units)
        final path = PathfindingService.findPath('A', 'C', rooms, corridors);

        expect(path, ['A', 'B', 'C']);
      });

      test('should avoid closed rooms', () {
        final closedRooms = List<Room>.from(rooms);
        closedRooms[1] = const Room(
          id: 'B',
          floorId: 'floor1',
          name: 'Room B',
          x: 10,
          y: 0,
          type: RoomType.hallway,
          isClosed: true,
        );

        // Normal route A-B-C is blocked because B is closed. Should route A-D-E-C.
        final path = PathfindingService.findPath(
          'A',
          'C',
          closedRooms,
          corridors,
        );

        expect(path, ['A', 'D', 'E', 'C']);
      });

      test('should find path when multiple routes exist', () {
        // A -> E: A-B-C-E (30) vs A-D-E (30) - both same distance
        final path = PathfindingService.findPath('A', 'E', rooms, corridors);

        expect(path, isNotEmpty);
        expect(path.first, 'A');
        expect(path.last, 'E');
      });

      test('should return empty list when no path exists', () {
        // Isolated room with no connections
        final isolatedRooms = [
          ...rooms,
          const Room(
            id: 'F',
            floorId: 'floor2',
            name: 'Isolated',
            x: 100,
            y: 100,
            type: RoomType.room,
          ),
        ];

        final path = PathfindingService.findPath(
          'A',
          'F',
          isolatedRooms,
          corridors,
        );

        expect(path, isEmpty);
      });

      test('should return path with single element when start equals end', () {
        final path = PathfindingService.findPath('A', 'A', rooms, corridors);

        expect(path, ['A']);
      });

      test('should return empty list when start room does not exist', () {
        final path = PathfindingService.findPath(
          'INVALID',
          'B',
          rooms,
          corridors,
        );

        expect(path, isEmpty);
      });

      test('should return empty list when end room does not exist', () {
        final path = PathfindingService.findPath(
          'A',
          'INVALID',
          rooms,
          corridors,
        );

        expect(path, isEmpty);
      });
    });

    group('Accessibility Mode', () {
      late List<Room> accessibleRooms;
      late List<Corridor> accessibleCorridors;

      setUp(() {
        // Setup with stairs and elevator:
        // Ground: A --> B
        // B --> Stairs --> C (Floor 1) - shorter
        // B --> Elevator --> C (Floor 1) - longer
        accessibleRooms = [
          const Room(
            id: 'A',
            floorId: 'ground',
            name: 'Start',
            x: 0,
            y: 0,
            type: RoomType.room,
          ),
          const Room(
            id: 'B',
            floorId: 'ground',
            name: 'Hall',
            x: 10,
            y: 0,
            type: RoomType.hallway,
          ),
          const Room(
            id: 'Stairs',
            floorId: 'ground',
            name: 'Stairs',
            x: 10,
            y: 5,
            type: RoomType.stairs,
          ),
          const Room(
            id: 'Elevator',
            floorId: 'ground',
            name: 'Lift',
            x: 10,
            y: -5,
            type: RoomType.elevator,
          ),
          const Room(
            id: 'C',
            floorId: 'floor1',
            name: 'End',
            x: 10,
            y: 0,
            type: RoomType.room,
          ),
        ];

        accessibleCorridors = [
          const Corridor(
            id: 'c1',
            floorId: 'ground',
            startRoomId: 'A',
            endRoomId: 'B',
            distance: 10,
          ),
          const Corridor(
            id: 'c2',
            floorId: 'ground',
            startRoomId: 'B',
            endRoomId: 'Stairs',
            distance: 5,
          ),
          const Corridor(
            id: 'c3',
            floorId: 'vertical',
            startRoomId: 'Stairs',
            endRoomId: 'C',
            distance: 10,
          ),
          const Corridor(
            id: 'c4',
            floorId: 'ground',
            startRoomId: 'B',
            endRoomId: 'Elevator',
            distance: 5,
          ),
          const Corridor(
            id: 'c5',
            floorId: 'vertical',
            startRoomId: 'Elevator',
            endRoomId: 'C',
            distance: 20,
          ),
        ];
      });

      test('should choose stairs (shorter) when accessible mode is OFF', () {
        final path = PathfindingService.findPath(
          'A',
          'C',
          accessibleRooms,
          accessibleCorridors,
          isAccessible: false,
        );

        expect(path, contains('Stairs'));
        expect(path, isNot(contains('Elevator')));
      });

      test('should avoid stairs when accessible mode is ON', () {
        final path = PathfindingService.findPath(
          'A',
          'C',
          accessibleRooms,
          accessibleCorridors,
          isAccessible: true,
        );

        expect(path, contains('Elevator'));
        expect(path, isNot(contains('Stairs')));
      });

      test(
        'should return empty when only stairs available and accessible mode ON',
        () {
          // Remove elevator route
          final stairsOnly = accessibleCorridors
              .where((c) => c.id != 'c4' && c.id != 'c5')
              .toList();

          final path = PathfindingService.findPath(
            'A',
            'C',
            accessibleRooms,
            stairsOnly,
            isAccessible: true,
          );

          expect(path, isEmpty);
        },
      );
    });

    group('Heuristic and Edge Cases', () {
      test('should handle rooms on different floors correctly', () {
        final multiFloorRooms = [
          const Room(
            id: 'A',
            floorId: 'floor1',
            name: 'Room A',
            x: 0,
            y: 0,
            type: RoomType.room,
          ),
          const Room(
            id: 'B',
            floorId: 'floor2',
            name: 'Room B',
            x: 0,
            y: 0,
            type: RoomType.room,
          ),
        ];
        final multiFloorCorridors = [
          const Corridor(
            id: 'c1',
            floorId: 'vertical',
            startRoomId: 'A',
            endRoomId: 'B',
            distance: 15,
          ),
        ];

        final path = PathfindingService.findPath(
          'A',
          'B',
          multiFloorRooms,
          multiFloorCorridors,
        );

        expect(path, ['A', 'B']);
      });

      test('should handle large distance values', () {
        final farRooms = [
          const Room(
            id: 'A',
            floorId: 'floor1',
            name: 'Start',
            x: 0,
            y: 0,
            type: RoomType.room,
          ),
          const Room(
            id: 'B',
            floorId: 'floor1',
            name: 'End',
            x: 10000,
            y: 10000,
            type: RoomType.room,
          ),
        ];
        final farCorridors = [
          const Corridor(
            id: 'c1',
            floorId: 'floor1',
            startRoomId: 'A',
            endRoomId: 'B',
            distance: 14142,
          ),
        ];

        final path = PathfindingService.findPath(
          'A',
          'B',
          farRooms,
          farCorridors,
        );

        expect(path, ['A', 'B']);
      });

      test('should handle single room in graph', () {
        final singleRoom = [
          const Room(
            id: 'A',
            floorId: 'floor1',
            name: 'Only',
            x: 0,
            y: 0,
            type: RoomType.room,
          ),
        ];

        final path = PathfindingService.findPath('A', 'A', singleRoom, []);

        expect(path, ['A']);
      });

      test('should handle empty graph', () {
        final path = PathfindingService.findPath('A', 'B', [], []);

        expect(path, isEmpty);
      });
    });

    group('Virtual Edge Penalty', () {
      test('should prefer longer detailed path over shorter virtual edge', () {
        final penaltyRooms = [
          const Room(
            id: 'Start',
            floorId: 'campus',
            name: 'Start',
            x: 0,
            y: 0,
            type: RoomType.entrance,
          ),
          const Room(
            id: 'Mid1',
            floorId: 'campus',
            name: 'Mid1',
            x: 0,
            y: 5,
            type: RoomType.hallway,
          ),
          const Room(
            id: 'Mid2',
            floorId: 'campus',
            name: 'Mid2',
            x: 0,
            y: 10,
            type: RoomType.hallway,
          ),
          const Room(
            id: 'End',
            floorId: 'campus',
            name: 'End',
            x: 0,
            y: 15,
            type: RoomType.entrance,
          ),
        ];

        // 1. Virtual Edge (Direct):
        // Distance 10. Cost = 10 * 3 = 30.
        const virtualEdge = Corridor(
          id: 'virtual_campus_Start_End',
          floorId: 'campus',
          startRoomId: 'Start',
          endRoomId: 'End',
          distance: 10,
        );

        // 2. Physical Path (Detailed):
        // Start->Mid1 (5) + Mid1->Mid2 (5) + Mid2->End (5) = 15.
        // Cost = 15.
        // 15 < 30, so A* should choose physical path even though physical distance (15) > virtual distance (10).
        final physicalEdges = [
          const Corridor(
            id: 'c1',
            floorId: 'campus',
            startRoomId: 'Start',
            endRoomId: 'Mid1',
            distance: 5,
          ),
          const Corridor(
            id: 'c2',
            floorId: 'campus',
            startRoomId: 'Mid1',
            endRoomId: 'Mid2',
            distance: 5,
          ),
          const Corridor(
            id: 'c3',
            floorId: 'campus',
            startRoomId: 'Mid2',
            endRoomId: 'End',
            distance: 5,
          ),
        ];

        final path = PathfindingService.findPath('Start', 'End', penaltyRooms, [
          virtualEdge,
          ...physicalEdges,
        ]);

        // Should choose physical path (Start -> Mid1 -> Mid2 -> End)
        expect(path, ['Start', 'Mid1', 'Mid2', 'End']);
      });

      test('should fallback to virtual edge if it is the only path', () {
        final penaltyRooms = [
          const Room(
            id: 'Start',
            floorId: 'campus',
            name: 'Start',
            x: 0,
            y: 0,
            type: RoomType.entrance,
          ),
          const Room(
            id: 'End',
            floorId: 'campus',
            name: 'End',
            x: 100,
            y: 0,
            type: RoomType.entrance,
          ),
        ];

        final penaltyCorridors = [
          const Corridor(
            id: 'virtual_campus_Start_End',
            floorId: 'campus',
            startRoomId: 'Start',
            endRoomId: 'End',
            distance: 100,
          ),
        ];

        final path = PathfindingService.findPath(
          'Start',
          'End',
          penaltyRooms,
          penaltyCorridors,
        );

        expect(path, ['Start', 'End']);
      });
    });
  });
}
