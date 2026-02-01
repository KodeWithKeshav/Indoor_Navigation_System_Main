import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/core/services/navigation_instruction_service.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';

void main() {
  late NavigationInstructionService service;

  setUp(() {
    service = NavigationInstructionService();
  });

  test('should generate "Exit elevator" instruction when previous node is elevator', () {
    final start = Room(id: '1', floorId: 'f1', name: 'Start', x: 0, y: 0, type: RoomType.room);
    final elevatorEntry = Room(id: '2', floorId: 'f1', name: 'Elevator F1', x: 10, y: 0, type: RoomType.elevator, connectorId: 'E1');
    final elevatorExit = Room(id: '3', floorId: 'f2', name: 'Elevator F2', x: 10, y: 0, type: RoomType.elevator, connectorId: 'E1');
    final end = Room(id: '4', floorId: 'f2', name: 'End', x: 20, y: 0, type: RoomType.room);

    final path = [start, elevatorEntry, elevatorExit, end];
    final floorLevels = {'f1': 1, 'f2': 2};

    final instructions = service.generateInstructions(path, floorLevels: floorLevels);

    // Initial instruction
    expect(instructions[0].message, contains('Start at'));

    // Walk to elevator
    expect(instructions[1].message, contains('Walk straight'));

    // Take elevator
    expect(instructions[2].message, contains('Take elevator up'));

    // KEY TEST: Exit elevator
    expect(instructions[3].message, contains('Exit elevator and walk forward'));

    // Arrival
    expect(instructions[4].message, contains('Arrive at'));
  });

  test('should generate "Exit stairs" instruction when previous node is stairs', () {
    final start = Room(id: '1', floorId: 'f1', name: 'Start', x: 0, y: 0, type: RoomType.room);
    final stairsEntry = Room(id: '2', floorId: 'f1', name: 'Stairs F1', x: 10, y: 0, type: RoomType.stairs, connectorId: 'S1');
    final stairsExit = Room(id: '3', floorId: 'f2', name: 'Stairs F2', x: 10, y: 0, type: RoomType.stairs, connectorId: 'S1');
    final end = Room(id: '4', floorId: 'f2', name: 'End', x: 20, y: 0, type: RoomType.room);

    final path = [start, stairsEntry, stairsExit, end];
    final floorLevels = {'f1': 1, 'f2': 2};

    final instructions = service.generateInstructions(path, floorLevels: floorLevels);

    // Initial instruction
    expect(instructions[0].message, contains('Start at'));

    // Walk to stairs
    expect(instructions[1].message, contains('Walk straight'));

    // Take stairs
    expect(instructions[2].message, contains('Take stairs up'));

    // KEY TEST: Exit stairs
    expect(instructions[3].message, contains('Exit stairs and walk forward'));

    // Arrival
    expect(instructions[4].message, contains('Arrive at'));
  });

  // --- NEW ORIENTATION TESTS ---
  
  test('should generate "Turn Right" at start if facing North (0) and path is East (90)', () {
      final start = const Room(id: '1', floorId: 'f1', name: 'Start', x: 0, y: 0, type: RoomType.room);
      final next = const Room(id: '2', floorId: 'f1', name: 'Next', x: 10, y: 0, type: RoomType.room);
      
      final path = [start, next];
      
      final instructions = service.generateInstructions(path, currentHeading: 0.0);
      
      expect(instructions[1].message, contains('Turn Right'));
      expect(instructions[1].icon, equals('right'));
  });

  test('should generate "Turn Left" at start if facing East (90) and path is North (0)', () {
      final start = const Room(id: '1', floorId: 'f1', name: 'Start', x: 0, y: 0, type: RoomType.room);
      final next = const Room(id: '2', floorId: 'f1', name: 'Next', x: 0, y: 10, type: RoomType.room);
      
      final path = [start, next];

      // Assuming Code assumes +Y is North (Cartesian)
      
      final instructions = service.generateInstructions(path, currentHeading: 90.0);
      
      expect(instructions[1].message, contains('Turn Left'));
      expect(instructions[1].icon, equals('left'));
  });
}
