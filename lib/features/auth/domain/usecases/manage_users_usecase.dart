import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class ManageUsersUseCase {
  final AuthRepository _authRepository;

  ManageUsersUseCase(this._authRepository);

  Future<Either<Failure, List<UserEntity>>> getAllUsers() {
    return _authRepository.getAllUsers();
  }

  Future<Either<Failure, void>> updateUserRole({
    required String uid,
    required String role,
  }) {
    return _authRepository.updateUserRole(uid: uid, role: role);
  }
}
