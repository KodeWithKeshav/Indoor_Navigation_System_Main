import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/core/services/graph_service.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/campus_entities.dart';
import '../../../test_utils/fakes.dart';

void main() {
  test('GraphService builds graph and maps floors to buildings', () async {
    final building = Building(id: 'b1', name: 'Main', description: 'desc');
    final floor = Floor(id: 'f1', buildingId: 'b1', floorNumber: 1, name: 'Floor 1');
    final rooms = [
      Room(id: 'r1', floorId: 'f1', name: 'Room 1', x: 0, y: 0),
      Room(id: 'r2', floorId: 'f1', name: 'Room 2', x: 1, y: 1),
    ];
    final corridors = [
      Corridor(id: 'c1', floorId: 'f1', startRoomId: 'r1', endRoomId: 'r2', distance: 2),
    ];

    final repo = FakeAdminMapRepository(
      buildings: [building],
      floorsByBuilding: {'b1': [floor]},
      roomsByFloor: {'f1': rooms},
      corridorsByFloor: {'f1': corridors},
      campusConnections: const <CampusConnection>[],
    );

    final service = GraphService(repo);
    final result = await service.buildGraph();

    expect(result, const Right(null));
    expect(service.allRooms.length, rooms.length);
    expect(service.allCorridors.length, corridors.length);
    expect(service.getBuildingIdForFloor('f1'), 'b1');
    expect(service.floorLevels['f1'], 1);
  });
}
