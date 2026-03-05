import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_map_repository.dart';

class DeleteRoomParams {
  final String buildingId;
  final String floorId;
  final String roomId;
  DeleteRoomParams(this.buildingId, this.floorId, this.roomId);
}

class DeleteRoomUseCase implements UseCase<void, DeleteRoomParams> {
  final AdminMapRepository repository;
  DeleteRoomUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteRoomParams params) {
    return repository.deleteRoom(
      params.buildingId,
      params.floorId,
      params.roomId,
    );
  }
}
