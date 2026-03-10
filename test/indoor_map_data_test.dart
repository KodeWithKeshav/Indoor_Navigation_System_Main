import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/core/errors/failure.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/campus_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/repositories/admin_map_repository.dart';

/// Fake implementation of AdminMapRepository for testing
class FakeAdminMapRepository implements AdminMapRepository {
  // Storage for fake data
  final List<Organization> _organizations = [];
  final List<Building> _buildings = [];
  final Map<String, List<Floor>> _floors = {};
  final Map<String, List<Room>> _rooms = {};
  final Map<String, List<Corridor>> _corridors = {};
  final List<CampusConnection> _campusConnections = [];

  // Flags to simulate failures
  bool shouldFail = false;
  String failureMessage = 'Test failure';

  void reset() {
    _organizations.clear();
    _buildings.clear();
    _floors.clear();
    _rooms.clear();
    _corridors.clear();
    _campusConnections.clear();
    shouldFail = false;
    failureMessage = 'Test failure';
  }

  @override
  Future<Either<Failure, void>> addOrganization(
    String name,
    String description,
  ) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    _organizations.add(
      Organization(
        id: 'org-${_organizations.length + 1}',
        name: name,
        description: description,
      ),
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Organization>>> getOrganizations() async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    return Right(_organizations);
  }

  @override
  Future<Either<Failure, void>> deleteOrganization(
    String organizationId,
  ) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    _organizations.removeWhere((o) => o.id == organizationId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateOrganization(
    String organizationId,
    String name,
    String description,
  ) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    final index = _organizations.indexWhere((o) => o.id == organizationId);
    if (index != -1) {
      _organizations[index] = Organization(
        id: organizationId,
        name: name,
        description: description,
      );
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> addBuilding(
    String name,
    String description,
    String? organizationId,
  ) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    _buildings.add(
      Building(
        id: 'b-${_buildings.length + 1}',
        name: name,
        description: description,
        organizationId: organizationId,
      ),
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Building>>> getBuildings({
    String? organizationId,
  }) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    if (organizationId != null) {
      return Right(
        _buildings.where((b) => b.organizationId == organizationId).toList(),
      );
    }
    return Right(_buildings);
  }

  @override
  Future<Either<Failure, void>> deleteBuilding(String buildingId) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    _buildings.removeWhere((b) => b.id == buildingId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateBuilding(
    String buildingId,
    String name,
    String description,
  ) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    final index = _buildings.indexWhere((b) => b.id == buildingId);
    if (index != -1) {
      final old = _buildings[index];
      _buildings[index] = Building(
        id: buildingId,
        name: name,
        description: description,
        organizationId: old.organizationId,
      );
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> addFloor(
    String buildingId,
    int floorNumber,
    String name,
  ) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    _floors.putIfAbsent(buildingId, () => []);
    _floors[buildingId]!.add(
      Floor(
        id: 'f-${floorNumber}',
        buildingId: buildingId,
        floorNumber: floorNumber,
        name: name,
      ),
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Floor>>> getFloors(String buildingId) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    return Right(_floors[buildingId] ?? []);
  }

  @override
  Future<Either<Failure, void>> deleteFloor(
    String buildingId,
    String floorId,
  ) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    _floors[buildingId]?.removeWhere((f) => f.id == floorId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateFloor(
    String buildingId,
    String floorId,
    int floorNumber,
    String name,
  ) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    final floors = _floors[buildingId];
    if (floors != null) {
      final index = floors.indexWhere((f) => f.id == floorId);
      if (index != -1) {
        floors[index] = Floor(
          id: floorId,
          buildingId: buildingId,
          floorNumber: floorNumber,
          name: name,
        );
      }
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> addRoom(
    String buildingId,
    String floorId,
    String name,
    double x,
    double y, {
    RoomType type = RoomType.room,
    String? connectorId,
    bool isClosed = false,
  }) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    final key = '$buildingId-$floorId';
    _rooms.putIfAbsent(key, () => []);
    _rooms[key]!.add(
      Room(
        id: 'r-${_rooms[key]!.length + 1}',
        floorId: floorId,
        name: name,
        x: x,
        y: y,
        type: type,
        connectorId: connectorId,
        isClosed: isClosed,
      ),
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Room>>> getRooms(
    String buildingId,
    String floorId,
  ) async {
    if (shouldFail) return Left(ValidationFailure(failureMessage));
    final key = '$buildingId-$floorId';
    return Right(_rooms[key] ?? []);
  }

  @override
  Future<Either<Failure, void>> deleteRoom(
    String buildingId,
    String floorId,
    String roomId,
  ) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    final key = '$buildingId-$floorId';
    _rooms[key]?.removeWhere((r) => r.id == roomId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateRoom(
    String buildingId,
    String floorId,
    String roomId, {
    double? x,
    double? y,
    String? name,
    RoomType? type,
    String? connectorId,
    bool? isClosed,
  }) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    final key = '$buildingId-$floorId';
    final rooms = _rooms[key];
    if (rooms != null) {
      final index = rooms.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        final old = rooms[index];
        rooms[index] = Room(
          id: roomId,
          floorId: floorId,
          name: name ?? old.name,
          x: x ?? old.x,
          y: y ?? old.y,
          type: type ?? old.type,
          connectorId: connectorId ?? old.connectorId,
          isClosed: isClosed ?? old.isClosed,
        );
      }
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> addCorridor(
    String buildingId,
    String floorId,
    String startRoomId,
    String endRoomId,
    double distance,
  ) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    final key = '$buildingId-$floorId';
    _corridors.putIfAbsent(key, () => []);
    _corridors[key]!.add(
      Corridor(
        id: 'c-${_corridors[key]!.length + 1}',
        floorId: floorId,
        startRoomId: startRoomId,
        endRoomId: endRoomId,
        distance: distance,
      ),
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Corridor>>> getCorridors(
    String buildingId,
    String floorId,
  ) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    final key = '$buildingId-$floorId';
    return Right(_corridors[key] ?? []);
  }

  @override
  Future<Either<Failure, void>> addCampusConnection(
    String fromBuildingId,
    String toBuildingId,
    double distance,
  ) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    _campusConnections.add(
      CampusConnection(
        id: 'cc-${_campusConnections.length + 1}',
        fromBuildingId: fromBuildingId,
        toBuildingId: toBuildingId,
        distance: distance,
      ),
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<CampusConnection>>> getCampusConnections() async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    return Right(_campusConnections);
  }

  @override
  Future<Either<Failure, void>> deleteCampusConnection(
    String connectionId,
  ) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    _campusConnections.removeWhere((c) => c.id == connectionId);
    return const Right(null);
  }
}

void main() {
  late FakeAdminMapRepository repository;

  setUp(() {
    repository = FakeAdminMapRepository();
  });

  tearDown(() {
    repository.reset();
  });

  group('Indoor Map Data Setup & Management', () {
    // ============ ORGANIZATION TESTS ============
    group('Organization Management', () {
      test('should add a new organization successfully', () async {
        final result = await repository.addOrganization(
          'Tech University',
          'A modern tech campus',
        );

        expect(result.isRight(), true);
        final orgs = await repository.getOrganizations();
        expect(orgs.fold((l) => [], (r) => r).length, 1);
      });

      test('should handle failure when adding organization', () async {
        repository.shouldFail = true;
        repository.failureMessage = 'Database connection error';

        final result = await repository.addOrganization(
          'Tech University',
          'A modern tech campus',
        );

        expect(result.isLeft(), true);
        expect(
          result.fold((l) => l.message, (r) => ''),
          'Database connection error',
        );
      });

      test('should retrieve all organizations', () async {
        await repository.addOrganization('Org 1', 'First org');
        await repository.addOrganization('Org 2', 'Second org');

        final result = await repository.getOrganizations();

        expect(result.isRight(), true);
        expect(result.fold((l) => [], (r) => r).length, 2);
      });

      test('should delete an organization', () async {
        await repository.addOrganization('Test Org', 'To be deleted');
        final orgs = await repository.getOrganizations();
        final orgId = orgs.fold((l) => <Organization>[], (r) => r).first.id;

        final result = await repository.deleteOrganization(orgId);

        expect(result.isRight(), true);
        final remaining = await repository.getOrganizations();
        expect(remaining.fold((l) => [], (r) => r).length, 0);
      });

      test('should update organization details', () async {
        await repository.addOrganization('Old Name', 'Old desc');
        final orgs = await repository.getOrganizations();
        final orgId = orgs.fold((l) => <Organization>[], (r) => r).first.id;

        final result = await repository.updateOrganization(
          orgId,
          'New Name',
          'New desc',
        );

        expect(result.isRight(), true);
        final updated = await repository.getOrganizations();
        expect(
          updated.fold((l) => <Organization>[], (r) => r).first.name,
          'New Name',
        );
      });
    });

    // ============ BUILDING TESTS ============
    group('Building Management', () {
      test('should add a new building with organization', () async {
        final result = await repository.addBuilding(
          'Engineering Building',
          'Main engineering',
          'org-1',
        );

        expect(result.isRight(), true);
      });

      test('should add building without organization', () async {
        final result = await repository.addBuilding(
          'Standalone Building',
          'No org',
          null,
        );

        expect(result.isRight(), true);
      });

      test('should retrieve buildings for organization', () async {
        await repository.addBuilding('Building A', 'First', 'org-1');
        await repository.addBuilding('Building B', 'Second', 'org-1');
        await repository.addBuilding('Building C', 'Different org', 'org-2');

        final result = await repository.getBuildings(organizationId: 'org-1');

        expect(result.fold((l) => [], (r) => r).length, 2);
      });

      test('should delete a building', () async {
        await repository.addBuilding('To Delete', 'Delete me', null);
        final buildings = await repository.getBuildings();
        final buildingId = buildings
            .fold((l) => <Building>[], (r) => r)
            .first
            .id;

        final result = await repository.deleteBuilding(buildingId);

        expect(result.isRight(), true);
      });

      test('should update building details', () async {
        await repository.addBuilding('Old Building', 'Old desc', null);
        final buildings = await repository.getBuildings();
        final buildingId = buildings
            .fold((l) => <Building>[], (r) => r)
            .first
            .id;

        final result = await repository.updateBuilding(
          buildingId,
          'New Building',
          'New desc',
        );

        expect(result.isRight(), true);
      });
    });

    // ============ FLOOR TESTS ============
    group('Floor Management', () {
      test('should add floors to a building', () async {
        await repository.addFloor('b1', 0, 'Ground Floor');
        await repository.addFloor('b1', 1, 'First Floor');

        final result = await repository.getFloors('b1');

        expect(result.fold((l) => [], (r) => r).length, 2);
      });

      test('should delete a floor', () async {
        await repository.addFloor('b1', 0, 'Ground');
        final floors = await repository.getFloors('b1');
        final floorId = floors.fold((l) => <Floor>[], (r) => r).first.id;

        final result = await repository.deleteFloor('b1', floorId);

        expect(result.isRight(), true);
      });

      test('should update floor details', () async {
        await repository.addFloor('b1', 0, 'Ground');
        final floors = await repository.getFloors('b1');
        final floorId = floors.fold((l) => <Floor>[], (r) => r).first.id;

        final result = await repository.updateFloor(
          'b1',
          floorId,
          0,
          'Ground Floor Updated',
        );

        expect(result.isRight(), true);
      });
    });

    // ============ ROOM TESTS ============
    group('Room Management', () {
      test('should add a room with default type', () async {
        final result = await repository.addRoom(
          'b1',
          'f1',
          'Room 101',
          10.0,
          20.0,
        );

        expect(result.isRight(), true);
      });

      test('should add a hallway', () async {
        final result = await repository.addRoom(
          'b1',
          'f1',
          'Main Hallway',
          50.0,
          50.0,
          type: RoomType.hallway,
        );

        expect(result.isRight(), true);
        final rooms = await repository.getRooms('b1', 'f1');
        expect(
          rooms.fold((l) => <Room>[], (r) => r).first.type,
          RoomType.hallway,
        );
      });

      test('should add stairs with connector ID', () async {
        final result = await repository.addRoom(
          'b1',
          'f1',
          'Staircase A',
          30.0,
          30.0,
          type: RoomType.stairs,
          connectorId: 'stair-a',
        );

        expect(result.isRight(), true);
        final rooms = await repository.getRooms('b1', 'f1');
        expect(
          rooms.fold((l) => <Room>[], (r) => r).first.connectorId,
          'stair-a',
        );
      });

      test('should add an elevator', () async {
        final result = await repository.addRoom(
          'b1',
          'f1',
          'Elevator 1',
          40.0,
          40.0,
          type: RoomType.elevator,
          connectorId: 'elev-1',
        );

        expect(result.isRight(), true);
      });

      test('should retrieve all rooms on a floor', () async {
        await repository.addRoom('b1', 'f1', 'Room 1', 10.0, 10.0);
        await repository.addRoom('b1', 'f1', 'Room 2', 20.0, 20.0);
        await repository.addRoom(
          'b1',
          'f1',
          'Hallway',
          30.0,
          30.0,
          type: RoomType.hallway,
        );

        final result = await repository.getRooms('b1', 'f1');

        expect(result.fold((l) => [], (r) => r).length, 3);
      });

      test('should delete a room', () async {
        await repository.addRoom('b1', 'f1', 'Test Room', 10.0, 10.0);
        final rooms = await repository.getRooms('b1', 'f1');
        final roomId = rooms.fold((l) => <Room>[], (r) => r).first.id;

        final result = await repository.deleteRoom('b1', 'f1', roomId);

        expect(result.isRight(), true);
      });

      test('should update room coordinates', () async {
        await repository.addRoom('b1', 'f1', 'Room', 10.0, 10.0);
        final rooms = await repository.getRooms('b1', 'f1');
        final roomId = rooms.fold((l) => <Room>[], (r) => r).first.id;

        final result = await repository.updateRoom(
          'b1',
          'f1',
          roomId,
          x: 50.0,
          y: 60.0,
        );

        expect(result.isRight(), true);
      });
    });

    // ============ CORRIDOR TESTS ============
    group('Corridor Management', () {
      test('should add a corridor between rooms', () async {
        final result = await repository.addCorridor(
          'b1',
          'f1',
          'r1',
          'r2',
          25.5,
        );

        expect(result.isRight(), true);
      });

      test('should retrieve all corridors on a floor', () async {
        await repository.addCorridor('b1', 'f1', 'r1', 'r2', 10.0);
        await repository.addCorridor('b1', 'f1', 'r2', 'r3', 15.0);

        final result = await repository.getCorridors('b1', 'f1');

        expect(result.fold((l) => [], (r) => r).length, 2);
      });

      test('should calculate total corridor distance', () async {
        await repository.addCorridor('b1', 'f1', 'r1', 'r2', 10.0);
        await repository.addCorridor('b1', 'f1', 'r2', 'r3', 15.0);
        await repository.addCorridor('b1', 'f1', 'r3', 'r4', 12.0);

        final result = await repository.getCorridors('b1', 'f1');
        final corridors = result.fold((l) => <Corridor>[], (r) => r);
        final totalDistance = corridors
            .map((c) => c.distance)
            .reduce((a, b) => a + b);

        expect(totalDistance, 37.0);
      });
    });

    // ============ CAMPUS CONNECTION TESTS ============
    group('Campus Connection Management', () {
      test('should add connection between buildings', () async {
        final result = await repository.addCampusConnection('b1', 'b2', 150.0);

        expect(result.isRight(), true);
      });

      test('should retrieve all building connections', () async {
        await repository.addCampusConnection('b1', 'b2', 150.0);
        await repository.addCampusConnection('b2', 'b3', 200.0);

        final result = await repository.getCampusConnections();

        expect(result.fold((l) => [], (r) => r).length, 2);
      });

      test('should delete a campus connection', () async {
        await repository.addCampusConnection('b1', 'b2', 150.0);
        final connections = await repository.getCampusConnections();
        final connectionId = connections
            .fold((l) => <CampusConnection>[], (r) => r)
            .first
            .id;

        final result = await repository.deleteCampusConnection(connectionId);

        expect(result.isRight(), true);
      });

      test('should calculate total campus distance', () async {
        await repository.addCampusConnection('b1', 'b2', 150.0);
        await repository.addCampusConnection('b2', 'b3', 200.0);

        final result = await repository.getCampusConnections();
        final connections = result.fold((l) => <CampusConnection>[], (r) => r);
        final totalDistance = connections
            .map((c) => c.distance)
            .reduce((a, b) => a + b);

        expect(totalDistance, 350.0);
      });
    });

    // ============ ERROR HANDLING TESTS ============
    group('Error Handling', () {
      test('should handle database failure', () async {
        repository.shouldFail = true;
        repository.failureMessage = 'Database connection error';

        final result = await repository.addOrganization('Test', 'Test');

        expect(result.isLeft(), true);
        expect(
          result.fold((l) => l.message, (r) => ''),
          'Database connection error',
        );
      });

      test('should handle empty list retrieval', () async {
        final result = await repository.getOrganizations();

        expect(result.isRight(), true);
        expect(result.fold((l) => null, (r) => r.isEmpty), true);
      });

      test('should handle validation failure when getting rooms', () async {
        repository.shouldFail = true;
        repository.failureMessage = 'Floor not found';

        final result = await repository.getRooms('b1', 'f1');

        expect(result.isLeft(), true);
      });
    });

    // ============ ENTITY MODEL TESTS ============
    group('Entity Models', () {
      test('Building equality', () {
        const building1 = Building(
          id: 'b1',
          name: 'Eng',
          description: 'Eng',
          organizationId: 'org-1',
        );
        const building2 = Building(
          id: 'b1',
          name: 'Eng',
          description: 'Eng',
          organizationId: 'org-1',
        );
        expect(building1, equals(building2));
      });

      test('Floor entity props', () {
        const floor = Floor(
          id: 'f1',
          buildingId: 'b1',
          floorNumber: 0,
          name: 'Ground',
        );
        expect(floor.props, contains('f1'));
        expect(floor.props, contains(0));
      });

      test('Room types exist', () {
        expect(RoomType.values.length, greaterThan(5));
        expect(RoomType.values, contains(RoomType.hallway));
        expect(RoomType.values, contains(RoomType.stairs));
        expect(RoomType.values, contains(RoomType.elevator));
      });

      test('Corridor has correct properties', () {
        const corridor = Corridor(
          id: 'c1',
          floorId: 'f1',
          startRoomId: 'r1',
          endRoomId: 'r2',
          distance: 25.5,
        );
        expect(corridor.distance, 25.5);
        expect(corridor.startRoomId, 'r1');
        expect(corridor.endRoomId, 'r2');
      });

      test('Room with connector ID', () {
        const room = Room(
          id: 'r1',
          floorId: 'f1',
          name: 'Staircase',
          x: 30.0,
          y: 30.0,
          type: RoomType.stairs,
          connectorId: 'stair-a',
        );
        expect(room.connectorId, 'stair-a');
        expect(room.type, RoomType.stairs);
      });

      test('CampusConnection has correct properties', () {
        const connection = CampusConnection(
          id: 'cc1',
          fromBuildingId: 'b1',
          toBuildingId: 'b2',
          distance: 150.0,
        );
        expect(connection.fromBuildingId, 'b1');
        expect(connection.toBuildingId, 'b2');
        expect(connection.distance, 150.0);
      });
    });

    // ============ INTEGRATION SCENARIOS ============
    group('Integration Scenarios', () {
      test('multi-floor building structure', () async {
        await repository.addFloor('b1', 0, 'Ground');
        await repository.addFloor('b1', 1, 'First');
        await repository.addFloor('b1', 2, 'Second');

        final floors = await repository.getFloors('b1');

        expect(floors.fold((l) => [], (r) => r).length, 3);
      });

      test('building with multiple rooms and corridors', () async {
        await repository.addRoom('b1', 'f1', 'Room 101', 10.0, 20.0);
        await repository.addRoom('b1', 'f1', 'Room 102', 30.0, 40.0);
        await repository.addRoom(
          'b1',
          'f1',
          'Hallway',
          50.0,
          50.0,
          type: RoomType.hallway,
        );
        await repository.addCorridor('b1', 'f1', 'r-1', 'r-3', 20.0);
        await repository.addCorridor('b1', 'f1', 'r-3', 'r-2', 25.0);

        final rooms = await repository.getRooms('b1', 'f1');
        final corridors = await repository.getCorridors('b1', 'f1');

        expect(rooms.fold((l) => [], (r) => r).length, 3);
        expect(corridors.fold((l) => [], (r) => r).length, 2);
      });

      test('vertical connections via stairs', () async {
        await repository.addRoom(
          'b1',
          'f1',
          'Staircase A',
          30.0,
          30.0,
          type: RoomType.stairs,
          connectorId: 'stair-a',
        );
        await repository.addRoom(
          'b1',
          'f2',
          'Staircase A',
          30.0,
          30.0,
          type: RoomType.stairs,
          connectorId: 'stair-a',
        );

        final floor1Rooms = await repository.getRooms('b1', 'f1');
        final floor2Rooms = await repository.getRooms('b1', 'f2');

        expect(
          floor1Rooms.fold((l) => <Room>[], (r) => r).first.connectorId,
          'stair-a',
        );
        expect(
          floor2Rooms.fold((l) => <Room>[], (r) => r).first.connectorId,
          'stair-a',
        );
      });

      test('campus with connected buildings', () async {
        await repository.addBuilding('Building A', 'First', 'org-1');
        await repository.addBuilding('Building B', 'Second', 'org-1');
        await repository.addCampusConnection('b-1', 'b-2', 150.0);

        final buildings = await repository.getBuildings(
          organizationId: 'org-1',
        );
        final connections = await repository.getCampusConnections();

        expect(buildings.fold((l) => [], (r) => r).length, 2);
        expect(connections.fold((l) => [], (r) => r).length, 1);
      });
    });
  });
}
