import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_map_repository.dart';

class UpdateOrganizationParams {
  final String id;
  final String name;
  final String description;
  UpdateOrganizationParams(this.id, this.name, this.description);
}

class UpdateOrganizationUseCase
    implements UseCase<void, UpdateOrganizationParams> {
  final AdminMapRepository repository;
  UpdateOrganizationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateOrganizationParams params) {
    return repository.updateOrganization(
      params.id,
      params.name,
      params.description,
    );
  }
}
