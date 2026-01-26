import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_map_repository.dart';

class DeleteOrganizationUseCase implements UseCase<void, String> {
  final AdminMapRepository repository;
  DeleteOrganizationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String organizationId) {
    return repository.deleteOrganization(organizationId);
  }
}
