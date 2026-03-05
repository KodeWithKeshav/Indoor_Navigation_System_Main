import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:indoor_navigation_system/core/errors/failure.dart';
import 'package:indoor_navigation_system/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:indoor_navigation_system/features/auth/data/models/user_model.dart';
import 'package:indoor_navigation_system/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:indoor_navigation_system/features/auth/domain/entities/user_entity.dart';

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  test('AuthRepositoryImpl returns user on login', () async {
    final remote = _MockAuthRemoteDataSource();
    final repo = AuthRepositoryImpl(remote);
    when(
      () => remote.loginWithEmailPassword(
        email: 'u1@example.com',
        password: 'pw',
      ),
    ).thenAnswer(
      (_) async => const UserModel(
        id: 'u1',
        email: 'u1@example.com',
        role: UserRole.user,
      ),
    );

    final result = await repo.loginWithEmailPassword(
      email: 'u1@example.com',
      password: 'pw',
    );

    expect(
      result
          .getOrElse(
            (_) => const UserEntity(id: 'x', email: '', role: UserRole.user),
          )
          .id,
      'u1',
    );
  });

  test('AuthRepositoryImpl returns failure on exception', () async {
    final remote = _MockAuthRemoteDataSource();
    final repo = AuthRepositoryImpl(remote);

    when(() => remote.logout()).thenThrow(Exception('boom'));

    final result = await repo.logout();
    expect(result.isLeft(), isTrue);
    expect(
      result.swap().getOrElse((_) => const ServerFailure('')).message,
      contains('boom'),
    );
  });
}
