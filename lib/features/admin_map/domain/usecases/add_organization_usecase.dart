import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_map_repository.dart';

class AddOrganizationParams {
  final String name;
  final String description;

  const AddOrganizationParams({required this.name, required this.description});
}

class AddOrganizationUseCase implements UseCase<void, AddOrganizationParams> {
  final AdminMapRepository repository;

  AddOrganizationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddOrganizationParams params) async {
    return await repository.addOrganization(params.name, params.description);
  }
}
