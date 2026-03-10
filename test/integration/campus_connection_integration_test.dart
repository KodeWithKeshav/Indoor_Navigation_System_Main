import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/core/services/pathfinding_service.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/campus_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/manage_campus_usecase.dart';
import 'package:indoor_navigation_system/core/usecase/usecase.dart';
import '../test_utils/fakes.dart';

void main() {
  group('Campus Connection Integration', () {
    late FakeAdminMapRepository repo;
    late AddCampusConnectionUseCase addConnection;
    late GetCampusConnectionsUseCase getConnections;
    late DeleteCampusConnectionUseCase deleteConnection;

    setUp(() {
      repo = FakeAdminMapRepository();
      addConnection = AddCampusConnectionUseCase(repo);
      getConnections = GetCampusConnectionsUseCase(repo);
      deleteConnection = DeleteCampusConnectionUseCase(repo);
    });

    test(
      'add campus connections via use cases → retrieve and verify',
      () async {
        // Add two connections
        expect(
          await addConnection(AddCampusConnectionParams('b1', 'b2', 100)),
          const Right(null),
        );
        expect(
          await addConnection(AddCampusConnectionParams('b2', 'b3', 150)),
          const Right(null),
        );

        // Retrieve
        final result = await getConnections(NoParams());
        expect(result.isRight(), isTrue);
        final connections = result.getRight().getOrElse(() => []);
        expect(connections.length, 2);
        expect(connections[0].fromBuildingId, 'b1');
        expect(connections[0].toBuildingId, 'b2');
        expect(connections[0].distance, 100);
        expect(connections[1].fromBuildingId, 'b2');
        expect(connections[1].toBuildingId, 'b3');
        expect(connections[1].distance, 150);
      },
    );

    test('delete campus connection → verify removed', () async {
      await addConnection(AddCampusConnectionParams('b1', 'b2', 100));
      await addConnection(AddCampusConnectionParams('b2', 'b3', 150));

      final before = (await getConnections(
        NoParams(),
      )).getRight().getOrElse(() => []);
      expect(before.length, 2);

      // Delete first connection
      expect(await deleteConnection(before.first.id), const Right(null));

      final after = (await getConnections(
        NoParams(),
      )).getRight().getOrElse(() => []);
      expect(after.length, 1);
      expect(after.first.fromBuildingId, 'b2');
    });

    test('pathfinding uses virtual edges across buildings with penalty', () {
      // Building A entrance → Building B entrance
      // Physical path: Start → Mid1 → Mid2 → End (5 + 5 + 5 = 15)
      // Virtual edge: Start → End (distance 10, penalized to 30)
      // A* should prefer the physical path (15 < 30)
      final rooms = [
        const Room(
          id: 'Start',
          floorId: 'campus',
          name: 'Building A Entrance',
          x: 0,
          y: 0,
          type: RoomType.entrance,
        ),
        const Room(
          id: 'Mid1',
          floorId: 'campus',
          name: 'Walkway 1',
          x: 0,
          y: 5,
          type: RoomType.hallway,
        ),
        const Room(
          id: 'Mid2',
          floorId: 'campus',
          name: 'Walkway 2',
          x: 0,
          y: 10,
          type: RoomType.hallway,
        ),
        const Room(
          id: 'End',
          floorId: 'campus',
          name: 'Building B Entrance',
          x: 0,
          y: 15,
          type: RoomType.entrance,
        ),
      ];

      final corridors = [
        // Virtual edge
        const Corridor(
          id: 'virtual_campus_A_B',
          floorId: 'campus',
          startRoomId: 'Start',
          endRoomId: 'End',
          distance: 10,
        ),
        // Physical path
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

      final path = PathfindingService.findPath(
        'Start',
        'End',
        rooms,
        corridors,
      );
      // Should prefer physical path due to virtual edge penalty
      expect(path, ['Start', 'Mid1', 'Mid2', 'End']);
    });

    test('virtual edge is used when it is the only path', () {
      final rooms = [
        const Room(
          id: 'A',
          floorId: 'campus',
          name: 'Building A',
          x: 0,
          y: 0,
          type: RoomType.entrance,
        ),
        const Room(
          id: 'B',
          floorId: 'campus',
          name: 'Building B',
          x: 100,
          y: 0,
          type: RoomType.entrance,
        ),
      ];

      final corridors = [
        const Corridor(
          id: 'virtual_campus_A_B',
          floorId: 'campus',
          startRoomId: 'A',
          endRoomId: 'B',
          distance: 100,
        ),
      ];

      final path = PathfindingService.findPath('A', 'B', rooms, corridors);
      expect(path, ['A', 'B']);
    });

    test('failure propagation in campus connection use cases', () async {
      repo.shouldFail = true;
      repo.failureMessage = 'DB connection lost';

      final addResult = await addConnection(
        AddCampusConnectionParams('b1', 'b2', 100),
      );
      expect(addResult.isLeft(), isTrue);

      final getResult = await getConnections(NoParams());
      expect(getResult.isLeft(), isTrue);

      final deleteResult = await deleteConnection('fake-id');
      expect(deleteResult.isLeft(), isTrue);
    });
  });
}
