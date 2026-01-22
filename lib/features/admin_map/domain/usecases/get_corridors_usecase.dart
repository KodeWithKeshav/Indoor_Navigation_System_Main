import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/map_entities.dart';
import '../repositories/admin_map_repository.dart';

class GetCorridorsParams {
  final String buildingId;
  final String floorId;
  GetCorridorsParams(this.buildingId, this.floorId);
}

class GetCorridorsUseCase implements UseCase<List<Corridor>, GetCorridorsParams> {
  final AdminMapRepository repository;
  GetCorridorsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Corridor>>> call(GetCorridorsParams params) {
    return repository.getCorridors(params.buildingId, params.floorId);
  }
}
