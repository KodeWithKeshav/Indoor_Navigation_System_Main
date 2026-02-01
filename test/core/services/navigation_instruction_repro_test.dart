import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/core/services/navigation_instruction_service.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';

void main() {
  late NavigationInstructionService service;

  setUp(() {
    service = NavigationInstructionService();
  });

  test('should generate separate "Turn around" and "Walk" instructions', () {
    // Scenario: User is at (0,0) facing North (0 degrees).
    // Destination is South at (0, -20).
    // Path: (0,0) -> (0, -20)
    
    final start = Room(id: '1', floorId: 'f1', name: 'Start', x: 0, y: 0, type: RoomType.room);
    final end = Room(id: '2', floorId: 'f1', name: 'End', x: 0, y: -20, type: RoomType.room);
    
    final path = [start, end];
    
    // Heading 0 (North). Path is moving South (180 degrees).
    // Angle difference should be 180 degrees -> "Turn around".
    final instructions = service.generateInstructions(path, currentHeading: 0.0);
    
    // DEBUG PRINT
    for (var i in instructions) {
      print('Instruction: ${i.message}, Distance: ${i.distance}, Icon: ${i.icon}');
    }

    // Expectation 1: "Turn around" instruction with 0 distance
    // Expectation 2: "Walk straight" instruction with 20 distance
    
    // Note: The ORIGINAL behavior (which we want to fix) would likely be:
    // One instruction: "Turn around" with distance 20.
    
    // Let's assert the DESIRED behavior.
    
    expect(instructions.length, greaterThanOrEqualTo(3)); // Start, Turn, Walk, Arrive is 4? Or Start, Turn+Walk (combined originally), Arrive
    
    // Index 0 is "Start at Start"
    expect(instructions[0].message, contains('Start at'));
    
    bool foundTurnAround = false;
    bool foundWalkAfterTurn = false;
    
    for (int i = 0; i < instructions.length; i++) {
      if (instructions[i].message.contains('Turn around') && instructions[i].distance == 0) {
        foundTurnAround = true;
      }
      if (foundTurnAround && instructions[i].message.contains('Walk') && instructions[i].distance == 20.0) {
        foundWalkAfterTurn = true;
      }
    }
    
    expect(foundTurnAround, isTrue, reason: 'Should have a separate turn around instruction with 0 distance');
    expect(foundWalkAfterTurn, isTrue, reason: 'Should have a walk instruction after turn around');
  });
}
