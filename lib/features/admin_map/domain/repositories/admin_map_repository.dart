import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../entities/map_entities.dart';
import '../entities/campus_entities.dart';

abstract interface class AdminMapRepository {
  // Organizations
  Future<Either<Failure, void>> addOrganization(
    String name,
    String description,
  );
  Future<Either<Failure, List<Organization>>> getOrganizations();
  Future<Either<Failure, void>> deleteOrganization(String organizationId);
  Future<Either<Failure, void>> updateOrganization(
    String organizationId,
    String name,
    String description,
  );

  // Buildings
  Future<Either<Failure, void>> addBuilding(
    String name,
    String description,
    String? organizationId,
  );
  Future<Either<Failure, List<Building>>> getBuildings({
    String? organizationId,
  });
  Future<Either<Failure, void>> deleteBuilding(String buildingId);
  Future<Either<Failure, void>> updateBuilding(
    String buildingId,
    String name,
    String description,
  );

  // Floors
  Future<Either<Failure, void>> addFloor(
    String buildingId,
    int floorNumber,
    String name,
  );
  Future<Either<Failure, List<Floor>>> getFloors(String buildingId);
  Future<Either<Failure, void>> deleteFloor(String buildingId, String floorId);
  Future<Either<Failure, void>> updateFloor(
    String buildingId,
    String floorId,
    int floorNumber,
    String name,
  );

  // Rooms
  Future<Either<Failure, void>> addRoom(
    String buildingId,
    String floorId,
    String name,
    double x,
    double y, {
    RoomType type = RoomType.room,
    String? connectorId,
  });
  Future<Either<Failure, List<Room>>> getRooms(
    String buildingId,
    String floorId,
  );
  Future<Either<Failure, void>> deleteRoom(
    String buildingId,
    String floorId,
    String roomId,
  );
  Future<Either<Failure, void>> updateRoom(
    String buildingId,
    String floorId,
    String roomId, {
    double? x,
    double? y,
    String? name,
    RoomType? type,
    String? connectorId,
  });

  // Corridors
  Future<Either<Failure, void>> addCorridor(
    String buildingId,
    String floorId,
    String startRoomId,
    String endRoomId,
    double distance,
  );
  Future<Either<Failure, List<Corridor>>> getCorridors(
    String buildingId,
    String floorId,
  );

  // Campus Connections
  Future<Either<Failure, void>> addCampusConnection(
    String fromBuildingId,
    String toBuildingId,
    double distance,
  );
  Future<Either<Failure, List<CampusConnection>>> getCampusConnections();
  Future<Either<Failure, void>> deleteCampusConnection(String connectionId);
}
