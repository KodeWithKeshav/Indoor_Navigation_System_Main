import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/map_entities.dart';
import '../repositories/admin_map_repository.dart';

// --- Buildings ---
class AddBuildingParams {
  final String name;
  final String description;
  final String? organizationId;
  AddBuildingParams(this.name, this.description, {this.organizationId});
}

class AddBuildingUseCase implements UseCase<void, AddBuildingParams> {
  final AdminMapRepository repository;
  AddBuildingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddBuildingParams params) {
    return repository.addBuilding(
      params.name,
      params.description,
      params.organizationId,
    );
  }
}

class GetBuildingsParams {
  final String? organizationId;
  GetBuildingsParams({this.organizationId});
}

class GetBuildingsUseCase
    implements UseCase<List<Building>, GetBuildingsParams> {
  final AdminMapRepository repository;
  GetBuildingsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Building>>> call(GetBuildingsParams params) {
    return repository.getBuildings(organizationId: params.organizationId);
  }
}

// --- Floors ---
class AddFloorParams {
  final String buildingId;
  final int floorNumber;
  final String name;
  AddFloorParams(this.buildingId, this.floorNumber, this.name);
}

class AddFloorUseCase implements UseCase<void, AddFloorParams> {
  final AdminMapRepository repository;
  AddFloorUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddFloorParams params) {
    return repository.addFloor(
      params.buildingId,
      params.floorNumber,
      params.name,
    );
  }
}

class GetFloorsUseCase implements UseCase<List<Floor>, String> {
  // String as Param = BuildingId
  final AdminMapRepository repository;
  GetFloorsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Floor>>> call(String buildingId) {
    return repository.getFloors(buildingId);
  }
}

// --- Rooms ---
class AddRoomParams {
  final String buildingId;
  final String floorId;
  final String name;
  final double x;
  final double y;
  final RoomType type;
  final String? connectorId;

  AddRoomParams({
    required this.buildingId,
    required this.floorId,
    required this.name,
    required this.x,
    required this.y,
    this.type = RoomType.room,
    this.connectorId,
  });
}

class AddRoomUseCase implements UseCase<void, AddRoomParams> {
  final AdminMapRepository repository;
  AddRoomUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddRoomParams params) {
    return repository.addRoom(
      params.buildingId,
      params.floorId,
      params.name,
      params.x,
      params.y,
      type: params.type,
      connectorId: params.connectorId,
    );
  }
}

class GetRoomsParams {
  final String buildingId;
  final String floorId;
  GetRoomsParams(this.buildingId, this.floorId);
}

class GetRoomsUseCase implements UseCase<List<Room>, GetRoomsParams> {
  final AdminMapRepository repository;
  GetRoomsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Room>>> call(GetRoomsParams params) {
    return repository.getRooms(params.buildingId, params.floorId);
  }
}
