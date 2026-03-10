import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/core/errors/failure.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/campus_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/repositories/admin_map_repository.dart';
import 'package:indoor_navigation_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:indoor_navigation_system/features/auth/domain/entities/user_entity.dart';

/// Fake implementation of AdminMapRepository for testing
class FakeAdminMapRepository implements AdminMapRepository {
  // Storage for fake data
  final List<Organization> _organizations = [];
  final List<Building> _buildings = [];
  final Map<String, List<Floor>> _floors = {};
  final Map<String, List<Room>> _rooms = {};
  final Map<String, List<Corridor>> _corridors = {};
  final List<CampusConnection> _campusConnections = [];

  FakeAdminMapRepository({
    List<Organization>? organizations,
    List<Building>? buildings,
    Map<String, List<Floor>>? floorsByBuilding,
    Map<String, List<Room>>? roomsByFloor,
    Map<String, List<Corridor>>? corridorsByFloor,
    List<CampusConnection>? campusConnections,
  }) {
    if (organizations != null) _organizations.addAll(organizations);
    if (buildings != null) _buildings.addAll(buildings);
    if (floorsByBuilding != null) _floors.addAll(floorsByBuilding);
    if (roomsByFloor != null) _rooms.addAll(roomsByFloor);
    if (corridorsByFloor != null) _corridors.addAll(corridorsByFloor);
    if (campusConnections != null) _campusConnections.addAll(campusConnections);
  }

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

/// Fake implementation of AuthRepository for testing
class FakeAuthRepository implements AuthRepository {
  final List<UserEntity> users;
  UserEntity? _currentUser;
  bool shouldFail = false;
  String failureMessage = 'Test failure';

  FakeAuthRepository({List<UserEntity>? users}) : users = users ?? [];

  @override
  Future<Either<Failure, UserEntity>> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    final user = users.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception('User not found'),
    ); // Should handle gracefully normally
    _currentUser = user;
    return Right(user);
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String organizationId,
  }) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    final newUser = UserEntity(
      id: 'u-${users.length + 1}',
      email: email,
      role: UserRole.user,
      organizationId: organizationId,
    );
    // In a real fake we would add to list, but here we just return
    return Right(newUser);
  }

  @override
  Future<Either<Failure, void>> logout() async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    _currentUser = null;
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    return Right(_currentUser);
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getAllUsers() async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    return Right(users);
  }

  @override
  Future<Either<Failure, void>> updateUserRole({
    required String uid,
    required String role,
  }) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    final index = users.indexWhere((u) => u.id == uid);
    if (index != -1) {
      final old = users[index];
      // Convert string role to enum
      final newRole = role == 'admin' ? UserRole.admin : UserRole.user;
      users[index] = UserEntity(
        id: uid,
        email: old.email,
        role: newRole,
        organizationId: old.organizationId,
      );
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateUserOrganization({
    required String uid,
    required String organizationId,
  }) async {
    if (shouldFail) return Left(ServerFailure(failureMessage));
    final index = users.indexWhere((u) => u.id == uid);
    if (index != -1) {
      final old = users[index];
      users[index] = UserEntity(
        id: uid,
        email: old.email,
        role: old.role,
        organizationId: organizationId,
      );
    }
    return const Right(null);
  }
}
