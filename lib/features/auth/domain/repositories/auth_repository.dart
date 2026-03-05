import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, UserEntity>> loginWithEmailPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String organizationId,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, UserEntity?>> getCurrentUser();

  Future<Either<Failure, List<UserEntity>>> getAllUsers();

  Future<Either<Failure, void>> updateUserRole({
    required String uid,
    required String role,
  });

  Future<Either<Failure, void>> updateUserOrganization({
    required String uid,
    required String organizationId,
  });
}
