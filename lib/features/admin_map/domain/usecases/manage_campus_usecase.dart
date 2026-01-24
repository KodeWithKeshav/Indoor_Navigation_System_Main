import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_map_repository.dart';
import '../entities/campus_entities.dart';

class AddCampusConnectionParams {
  final String fromBuildingId;
  final String toBuildingId;
  final double distance;

  AddCampusConnectionParams(this.fromBuildingId, this.toBuildingId, this.distance);
}

class AddCampusConnectionUseCase implements UseCase<void, AddCampusConnectionParams> {
  final AdminMapRepository repository;
  AddCampusConnectionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddCampusConnectionParams params) {
    return repository.addCampusConnection(params.fromBuildingId, params.toBuildingId, params.distance);
  }
}

class GetCampusConnectionsUseCase implements UseCase<List<CampusConnection>, NoParams> {
  final AdminMapRepository repository;
  GetCampusConnectionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CampusConnection>>> call(NoParams params) {
    return repository.getCampusConnections();
  }
}

class DeleteCampusConnectionUseCase implements UseCase<void, String> {
  final AdminMapRepository repository;
  DeleteCampusConnectionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String connectionId) {
    return repository.deleteCampusConnection(connectionId);
  }
}
