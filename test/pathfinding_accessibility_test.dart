import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/core/services/pathfinding_service.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';

void main() {
  group('PathfindingService Accessibility', () {
    // Setup a simple graph
    // Room A (Ground) --(Corridor 10m)--> Room B (Ground)
    // Room B --(Stairs 5m)--> Room C (Floor 1) 
    // Room B --(Elevator 20m)--> Room C (Floor 1)
    
    final roomA = Room(id: 'A', floorId: 'ground', name: 'Start', x: 0, y: 0, type: RoomType.room);
    final roomB = Room(id: 'B', floorId: 'ground', name: 'Hall', x: 10, y: 0, type: RoomType.hallway);
    
    // Stairs Node (Vertical connector)
    final stairs = Room(id: 'Stairs', floorId: 'ground', name: 'Stairs', x: 10, y: 5, type: RoomType.stairs);
    
    // Elevator Node
    final elevator = Room(id: 'Elevator', floorId: 'ground', name: 'Lift', x: 10, y: -5, type: RoomType.elevator);
    
    final roomC = Room(id: 'C', floorId: 'floor1', name: 'End', x: 10, y: 0, type: RoomType.room);
    
    final rooms = [roomA, roomB, stairs, elevator, roomC];
    
    // Edges
    final corridors = [
      Corridor(id: 'c1', floorId: 'ground', startRoomId: 'A', endRoomId: 'B', distance: 10),
      
      // Path via Stairs (Shorter)
      Corridor(id: 'c2', floorId: 'ground', startRoomId: 'B', endRoomId: 'Stairs', distance: 5),
      Corridor(id: 'c3', floorId: 'vertical', startRoomId: 'Stairs', endRoomId: 'C', distance: 10), // Stairs Vertical
      
      // Path via Elevator (Longer)
      Corridor(id: 'c4', floorId: 'ground', startRoomId: 'B', endRoomId: 'Elevator', distance: 5),
      Corridor(id: 'c5', floorId: 'vertical', startRoomId: 'Elevator', endRoomId: 'C', distance: 20), // Elevator Vertical
    ];

    test('Should choose stairs (shorter) when accessible mode is OFF', () {
      final path = PathfindingService.findPath('A', 'C', rooms, corridors, isAccessible: false);
      expect(path, contains('Stairs'));
      expect(path, isNot(contains('Elevator')));
    });

    test('Should avoid stairs when accessible mode is ON', () {
      final path = PathfindingService.findPath('A', 'C', rooms, corridors, isAccessible: true);
      expect(path, contains('Elevator')); // Should take longer but accessible path
      expect(path, isNot(contains('Stairs')));
    });
  });
}
