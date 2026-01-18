import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_map_repository.dart';
import '../entities/organization.dart';

class GetOrganizationsUseCase implements UseCase<List<Organization>, NoParams> {
  final AdminMapRepository repository;

  GetOrganizationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Organization>>> call(NoParams params) async {
    return await repository.getOrganizations();
  }
}
