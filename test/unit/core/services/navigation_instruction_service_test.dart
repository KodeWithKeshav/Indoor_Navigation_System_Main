import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/core/services/navigation_instruction_service.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';

void main() {
  late NavigationInstructionService service;

  setUp(() {
    service = NavigationInstructionService();
  });

  group('NavigationInstructionService', () {
    group('generateInstructions', () {
      test('should return empty list for empty path', () {
        final instructions = service.generateInstructions([]);
        
        expect(instructions, isEmpty);
      });

      test('should return finish instruction for single room path', () {
        final path = [
          const Room(id: 'A', floorId: 'floor1', name: 'Room A', x: 0, y: 0, type: RoomType.room),
        ];
        
        final instructions = service.generateInstructions(path);
        
        expect(instructions.length, 1);
        expect(instructions.first.message, 'You are at your destination');
        expect(instructions.first.icon, 'finish');
      });

      test('should generate start and finish instructions for two room path', () {
        final path = [
          const Room(id: 'A', floorId: 'floor1', name: 'Start Room', x: 0, y: 0, type: RoomType.room),
          const Room(id: 'B', floorId: 'floor1', name: 'End Room', x: 10, y: 0, type: RoomType.room),
        ];
        
        final instructions = service.generateInstructions(path);
        
        expect(instructions.length, greaterThanOrEqualTo(2));
        expect(instructions.first.message, contains('Start Room'));
        expect(instructions.last.message, contains('End Room'));
      });

      test('should preserve admin-defined corridor distance exactly', () {
        final path = [
          const Room(id: 'A', floorId: 'floor1', name: 'A', x: 0, y: 0, type: RoomType.room),
          const Room(id: 'B', floorId: 'floor1', name: 'B', x: 10, y: 0, type: RoomType.room),
        ];
        final corridors = [
          const Corridor(id: 'c1', floorId: 'floor1', startRoomId: 'A', endRoomId: 'B', distance: 25.5),
        ];
        
        final instructions = service.generateInstructions(path, corridors: corridors);
        
        // Find the walking instruction
        final walkInstruction = instructions.firstWhere(
          (i) => i.icon == 'straight',
          orElse: () => NavigationInstruction(message: '', distance: 0, icon: ''),
        );
        
        expect(walkInstruction.distance, 25.5);
      });

      test('should never combine turn and walk into one instruction', () {
        // Path: East → North (left turn)
        final path = [
          const Room(id: 'A', floorId: 'f1', name: 'A', x: 0, y: 0, type: RoomType.hallway),
          const Room(id: 'B', floorId: 'f1', name: 'B', x: 10, y: 0, type: RoomType.hallway),
          const Room(id: 'C', floorId: 'f1', name: 'Target', x: 10, y: -10, type: RoomType.room),
        ];
        final corridors = [
          const Corridor(id: 'c1', floorId: 'f1', startRoomId: 'A', endRoomId: 'B', distance: 15.0),
          const Corridor(id: 'c2', floorId: 'f1', startRoomId: 'B', endRoomId: 'C', distance: 20.0),
        ];
        
        final instructions = service.generateInstructions(path, corridors: corridors);
        
        // Verify no instruction has both a turn icon AND a non-zero distance
        for (final step in instructions) {
          if (step.icon == 'left' || step.icon == 'right' || 
              step.icon == 'sharp_left' || step.icon == 'sharp_right' ||
              step.icon == 'uturn') {
            expect(step.distance, equals(0),
              reason: 'Turn instruction "${step.message}" should have distance 0, got ${step.distance}');
          }
        }
      });
    });

    group('Vertical Transitions', () {
      test('should generate stairs up instruction', () {
        final path = [
          Room(id: 'A', floorId: 'floor1', name: 'Hall', x: 0, y: 0, type: RoomType.hallway, connectorId: 'StairA'),
          Room(id: 'B', floorId: 'floor2', name: 'Hall F2', x: 0, y: 0, type: RoomType.stairs, connectorId: 'StairA'),
          const Room(id: 'C', floorId: 'floor2', name: 'Destination', x: 10, y: 0, type: RoomType.room),
        ];
        final floorLevels = {'floor1': 0, 'floor2': 1};
        
        final instructions = service.generateInstructions(path, floorLevels: floorLevels);
        
        final stairInstruction = instructions.firstWhere(
          (i) => i.icon.contains('stairs'),
          orElse: () => NavigationInstruction(message: '', distance: 0, icon: ''),
        );
        
        expect(stairInstruction.icon, 'stairs_up');
        expect(stairInstruction.message, contains('stairs'));
        expect(stairInstruction.message, contains('up'));
      });

      test('should generate elevator down instruction', () {
        final path = [
          Room(id: 'A', floorId: 'floor2', name: 'Hall', x: 0, y: 0, type: RoomType.elevator, connectorId: 'ElevA'),
          Room(id: 'B', floorId: 'floor1', name: 'Hall F1', x: 0, y: 0, type: RoomType.elevator, connectorId: 'ElevA'),
          const Room(id: 'C', floorId: 'floor1', name: 'Destination', x: 10, y: 0, type: RoomType.room),
        ];
        final floorLevels = {'floor1': 0, 'floor2': 1};
        
        final instructions = service.generateInstructions(path, floorLevels: floorLevels);
        
        final elevatorInstruction = instructions.firstWhere(
          (i) => i.icon.contains('elevator'),
          orElse: () => NavigationInstruction(message: '', distance: 0, icon: ''),
        );
        
        expect(elevatorInstruction.icon, 'elevator_down');
        expect(elevatorInstruction.message, contains('elevator'));
        expect(elevatorInstruction.message, contains('down'));
      });
    });

    group('Turn Detection', () {
      test('should detect left turn', () {
        // Path goes: East → North (left turn)
        final path = [
          const Room(id: 'A', floorId: 'f1', name: 'A', x: 0, y: 0, type: RoomType.hallway),
          const Room(id: 'B', floorId: 'f1', name: 'B', x: 10, y: 0, type: RoomType.hallway),
          const Room(id: 'C', floorId: 'f1', name: 'Target', x: 10, y: -10, type: RoomType.room),
        ];
        
        final instructions = service.generateInstructions(path);
        
        final leftTurn = instructions.any((i) => i.icon == 'left' || i.message.toLowerCase().contains('left'));
        expect(leftTurn, isTrue);
      });

      test('should detect right turn', () {
        // Path goes: East → South (right turn)
        final path = [
          const Room(id: 'A', floorId: 'f1', name: 'A', x: 0, y: 0, type: RoomType.hallway),
          const Room(id: 'B', floorId: 'f1', name: 'B', x: 10, y: 0, type: RoomType.hallway),
          const Room(id: 'C', floorId: 'f1', name: 'Target', x: 10, y: 10, type: RoomType.room),
        ];
        
        final instructions = service.generateInstructions(path);
        
        final rightTurn = instructions.any((i) => i.icon == 'right' || i.message.toLowerCase().contains('right'));
        expect(rightTurn, isTrue);
      });

      test('should detect straight path', () {
        // Path goes straight: East → East
        final path = [
          const Room(id: 'A', floorId: 'f1', name: 'A', x: 0, y: 0, type: RoomType.hallway),
          const Room(id: 'B', floorId: 'f1', name: 'B', x: 10, y: 0, type: RoomType.hallway),
          const Room(id: 'C', floorId: 'f1', name: 'Target', x: 20, y: 0, type: RoomType.room),
        ];
        
        final instructions = service.generateInstructions(path);
        
        final hasStraight = instructions.any((i) => 
          i.icon == 'straight' || i.message.toLowerCase().contains('straight')
        );
        expect(hasStraight, isTrue);
      });

      test('should emit turn as separate step with zero distance', () {
        // Path: East → North (left turn)
        final path = [
          const Room(id: 'A', floorId: 'f1', name: 'A', x: 0, y: 0, type: RoomType.hallway),
          const Room(id: 'B', floorId: 'f1', name: 'B', x: 10, y: 0, type: RoomType.hallway),
          const Room(id: 'C', floorId: 'f1', name: 'Target', x: 10, y: -10, type: RoomType.room),
        ];
        
        final instructions = service.generateInstructions(path);
        
        final turnStep = instructions.firstWhere(
          (i) => i.icon == 'left',
          orElse: () => NavigationInstruction(message: '', distance: -1, icon: ''),
        );
        expect(turnStep.distance, 0, reason: 'Turn steps must have zero distance');
      });
    });

    group('Landmarks', () {
      test('should include landmark names in turn instructions', () {
        final path = [
          const Room(id: 'A', floorId: 'f1', name: 'A', x: 0, y: 0, type: RoomType.hallway),
          const Room(id: 'B', floorId: 'f1', name: 'B', x: 10, y: 0, type: RoomType.hallway),
          const Room(id: 'C', floorId: 'f1', name: 'Library', x: 10, y: 10, type: RoomType.library),
        ];
        
        final instructions = service.generateInstructions(path);
        
        final hasLibraryMention = instructions.any((i) => i.message.contains('Library'));
        expect(hasLibraryMention, isTrue);
      });
    });

    group('Building Transitions', () {
      test('should generate enter building step for entrance node', () {
        // Outdoor campus → Entrance → Indoor hallway
        final path = [
          const Room(id: 'A', floorId: 'campus', name: 'Quad', x: 0, y: 0, type: RoomType.ground),
          Room(id: 'B', floorId: 'floor1', name: 'Main Door', x: 10, y: 0, type: RoomType.entrance, connectorId: 'entrance1'),
          const Room(id: 'C', floorId: 'floor1', name: 'Lobby', x: 20, y: 0, type: RoomType.hallway),
        ];
        
        final instructions = service.generateInstructions(path);
        
        final enterStep = instructions.any(
          (i) => i.message.toLowerCase().contains('enter'),
        );
        expect(enterStep, isTrue, reason: 'Should generate an "Enter building" step');
      });

      test('should generate exit building step for entrance node', () {
        // Indoor hallway → Entrance → Outdoor campus
        final path = [
          const Room(id: 'A', floorId: 'floor1', name: 'Lobby', x: 0, y: 0, type: RoomType.hallway),
          Room(id: 'B', floorId: 'campus', name: 'Main Door', x: 10, y: 0, type: RoomType.entrance, connectorId: 'entrance1'),
          const Room(id: 'C', floorId: 'campus', name: 'Quad', x: 20, y: 0, type: RoomType.ground),
        ];
        
        final instructions = service.generateInstructions(path);
        
        final exitStep = instructions.any(
          (i) => i.message.toLowerCase().contains('exit'),
        );
        expect(exitStep, isTrue, reason: 'Should generate an "Exit building" step');
      });
    });

    group('Edge Cases', () {
      test('should handle path with only hallways', () {
        final path = [
          const Room(id: 'A', floorId: 'f1', name: 'Hall A', x: 0, y: 0, type: RoomType.hallway),
          const Room(id: 'B', floorId: 'f1', name: 'Hall B', x: 10, y: 0, type: RoomType.hallway),
          const Room(id: 'C', floorId: 'f1', name: 'Hall C', x: 20, y: 0, type: RoomType.hallway),
        ];
        
        final instructions = service.generateInstructions(path);
        
        expect(instructions, isNotEmpty);
        expect(instructions.first.message, contains('Hall A'));
      });

      test('should handle path with same coordinates (zero distance)', () {
        final path = [
          const Room(id: 'A', floorId: 'f1', name: 'A', x: 0, y: 0, type: RoomType.room),
          const Room(id: 'B', floorId: 'f1', name: 'B', x: 0, y: 0, type: RoomType.room),
        ];
        
        final instructions = service.generateInstructions(path);
        
        expect(instructions, isNotEmpty);
      });

      test('should calculate Euclidean distance when no corridor provided', () {
        final path = [
          const Room(id: 'A', floorId: 'f1', name: 'A', x: 0, y: 0, type: RoomType.room),
          const Room(id: 'B', floorId: 'f1', name: 'B', x: 3, y: 4, type: RoomType.room),
        ];
        
        final instructions = service.generateInstructions(path);
        
        // Euclidean distance = sqrt(3^2 + 4^2) = 5
        final walkInstruction = instructions.firstWhere(
          (i) => i.distance > 0,
          orElse: () => NavigationInstruction(message: '', distance: 0, icon: ''),
        );
        
        expect(walkInstruction.distance, closeTo(5.0, 0.01));
      });

      test('should merge consecutive straight walks through hallway nodes', () {
        // Three hallway nodes in a line: A → B → C → D
        final path = [
          const Room(id: 'A', floorId: 'f1', name: 'A', x: 0, y: 0, type: RoomType.hallway),
          const Room(id: 'B', floorId: 'f1', name: 'B', x: 10, y: 0, type: RoomType.hallway),
          const Room(id: 'C', floorId: 'f1', name: 'C', x: 20, y: 0, type: RoomType.hallway),
          const Room(id: 'D', floorId: 'f1', name: 'Target', x: 30, y: 0, type: RoomType.room),
        ];
        final corridors = [
          const Corridor(id: 'c1', floorId: 'f1', startRoomId: 'A', endRoomId: 'B', distance: 10),
          const Corridor(id: 'c2', floorId: 'f1', startRoomId: 'B', endRoomId: 'C', distance: 10),
          const Corridor(id: 'c3', floorId: 'f1', startRoomId: 'C', endRoomId: 'D', distance: 10),
        ];

        final instructions = service.generateInstructions(path, corridors: corridors);

        // Should have: Start, Walk straight (30m total), Arrive
        final walkSteps = instructions.where((i) => i.icon == 'straight').toList();
        expect(walkSteps.length, 1, reason: 'Consecutive straight walks should merge into one');
        expect(walkSteps.first.distance, 30.0, reason: 'Total distance should be sum of segments');
      });
    });
  });
}
