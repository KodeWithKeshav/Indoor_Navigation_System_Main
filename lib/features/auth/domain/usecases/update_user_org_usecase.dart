import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class UpdateUserOrgUseCase implements UseCase<void, UpdateUserOrgParams> {
  final AuthRepository repository;

  UpdateUserOrgUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUserOrgParams params) async {
    return await repository.updateUserOrganization(
      uid: params.uid,
      organizationId: params.organizationId,
    );
  }
}

class UpdateUserOrgParams {
  final String uid;
  final String organizationId;

  const UpdateUserOrgParams({
    required this.uid,
    required this.organizationId,
  });
}
