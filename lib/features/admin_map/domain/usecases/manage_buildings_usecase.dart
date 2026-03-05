import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_map_repository.dart';

class DeleteBuildingUseCase implements UseCase<void, String> {
  final AdminMapRepository repository;
  DeleteBuildingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String buildingId) {
    return repository.deleteBuilding(buildingId);
  }
}

class UpdateBuildingParams {
  final String id;
  final String name;
  final String description;
  UpdateBuildingParams(this.id, this.name, this.description);
}

class UpdateBuildingUseCase implements UseCase<void, UpdateBuildingParams> {
  final AdminMapRepository repository;
  UpdateBuildingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateBuildingParams params) {
    return repository.updateBuilding(
      params.id,
      params.name,
      params.description,
    );
  }
}
