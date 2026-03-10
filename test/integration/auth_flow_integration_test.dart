import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/features/auth/domain/entities/user_entity.dart';
import 'package:indoor_navigation_system/features/auth/domain/usecases/login_usecase.dart';
import 'package:indoor_navigation_system/features/auth/domain/usecases/signup_usecase.dart';
import 'package:indoor_navigation_system/core/errors/failure.dart';
import '../test_utils/fakes.dart';

void main() {
  group('Auth Flow Integration', () {
    late FakeAuthRepository repo;
    late LoginUseCase loginUseCase;
    late SignUpUseCase signUpUseCase;

    setUp(() {
      repo = FakeAuthRepository(
        users: [
          const UserEntity(
            id: 'u-1',
            email: 'admin@test.com',
            role: UserRole.admin,
            organizationId: 'org-1',
          ),
          const UserEntity(
            id: 'u-2',
            email: 'user@test.com',
            role: UserRole.user,
            organizationId: 'org-1',
          ),
        ],
      );
      loginUseCase = LoginUseCase(repo);
      signUpUseCase = SignUpUseCase(repo);
    });

    test('login → get current user → logout → current user is null', () async {
      // 1. Login
      final loginResult = await loginUseCase(
        LoginParams(email: 'admin@test.com', password: 'pass'),
      );
      expect(loginResult.isRight(), isTrue);
      loginResult.fold((_) => fail('Should not fail'), (user) {
        expect(user.email, 'admin@test.com');
        expect(user.role, UserRole.admin);
      });

      // 2. Get current user should return logged-in user
      final currentResult = await repo.getCurrentUser();
      currentResult.fold((_) => fail('Should not fail'), (user) {
        expect(user, isNotNull);
        expect(user!.email, 'admin@test.com');
      });

      // 3. Logout
      final logoutResult = await repo.logout();
      expect(logoutResult, const Right(null));

      // 4. Current user should be null after logout
      final afterLogout = await repo.getCurrentUser();
      afterLogout.fold(
        (_) => fail('Should not fail'),
        (user) => expect(user, isNull),
      );
    });

    test('sign up creates new user with correct role and org', () async {
      final signUpResult = await signUpUseCase(
        SignUpParams(
          email: 'new@test.com',
          password: 'password123',
          organizationId: 'org-2',
        ),
      );

      expect(signUpResult.isRight(), isTrue);
      signUpResult.fold((_) => fail('Should not fail'), (user) {
        expect(user.email, 'new@test.com');
        expect(user.role, UserRole.user);
        expect(user.organizationId, 'org-2');
      });
    });

    test(
      'login with valid credentials returns user with correct role',
      () async {
        // Login as regular user
        final result = await loginUseCase(
          LoginParams(email: 'user@test.com', password: 'pass'),
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Should not fail'), (user) {
          expect(user.email, 'user@test.com');
          expect(user.role, UserRole.user);
          expect(user.organizationId, 'org-1');
        });
      },
    );

    test('login failure propagates through use case', () async {
      repo.shouldFail = true;
      repo.failureMessage = 'Network error';

      final result = await loginUseCase(
        LoginParams(email: 'admin@test.com', password: 'pass'),
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Network error');
      }, (_) => fail('Should fail'));
    });

    test('sign up failure propagates through use case', () async {
      repo.shouldFail = true;
      repo.failureMessage = 'Email already exists';

      final result = await signUpUseCase(
        SignUpParams(
          email: 'new@test.com',
          password: 'pass',
          organizationId: 'org-1',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Email already exists');
      }, (_) => fail('Should fail'));
    });
  });
}
