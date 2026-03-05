import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_map_repository.dart';
import '../entities/map_entities.dart';

class UpdateRoomUseParams {
  final String buildingId;
  final String floorId;
  final String roomId;
  final double? x;
  final double? y;
  final String? name;
  final RoomType? type;
  final String? connectorId;

  UpdateRoomUseParams({
    required this.buildingId,
    required this.floorId,
    required this.roomId,
    this.x,
    this.y,
    this.name,
    this.type,
    this.connectorId,
  });
}

class UpdateRoomUseCase implements UseCase<void, UpdateRoomUseParams> {
  final AdminMapRepository repository;

  UpdateRoomUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateRoomUseParams params) async {
    return await repository.updateRoom(
      params.buildingId,
      params.floorId,
      params.roomId,
      x: params.x,
      y: params.y,
      name: params.name,
      type: params.type,
      connectorId: params.connectorId,
    );
  }
}
