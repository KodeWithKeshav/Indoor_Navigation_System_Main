import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_map_repository.dart';

class DeleteFloorParams {
  final String buildingId;
  final String floorId;
  DeleteFloorParams(this.buildingId, this.floorId);
}

class DeleteFloorUseCase implements UseCase<void, DeleteFloorParams> {
  final AdminMapRepository repository;
  DeleteFloorUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteFloorParams params) {
    return repository.deleteFloor(params.buildingId, params.floorId);
  }
}

class UpdateFloorParams {
  final String buildingId;
  final String floorId;
  final int floorNumber;
  final String name;
  UpdateFloorParams(this.buildingId, this.floorId, this.floorNumber, this.name);
}

class UpdateFloorUseCase implements UseCase<void, UpdateFloorParams> {
  final AdminMapRepository repository;
  UpdateFloorUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateFloorParams params) {
    return repository.updateFloor(
      params.buildingId,
      params.floorId,
      params.floorNumber,
      params.name,
    );
  }
}
