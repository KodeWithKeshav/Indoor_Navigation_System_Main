import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_map_repository.dart';

// --- Corridors ---
class AddCorridorParams {
  final String buildingId;
  final String floorId;
  final String startRoomId;
  final String endRoomId;
  final double distance;
  AddCorridorParams(this.buildingId, this.floorId, this.startRoomId, this.endRoomId, this.distance);
}

class AddCorridorUseCase implements UseCase<void, AddCorridorParams> {
  final AdminMapRepository repository;
  AddCorridorUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddCorridorParams params) {
    return repository.addCorridor(params.buildingId, params.floorId, params.startRoomId, params.endRoomId, params.distance);
  }
}
