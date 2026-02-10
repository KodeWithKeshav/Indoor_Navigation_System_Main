import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:indoor_navigation_system/features/auth/domain/usecases/login_usecase.dart';
import 'package:indoor_navigation_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:indoor_navigation_system/features/auth/domain/entities/user_entity.dart';
import 'package:indoor_navigation_system/core/errors/failure.dart';

// Mock class
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase loginUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    loginUseCase = LoginUseCase(mockAuthRepository);
  });

  group('LoginUseCase', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testUser = UserEntity(
      id: 'user-123',
      email: testEmail,
      role: UserRole.user,
      organizationId: 'org-1',
    );

    test('should return UserEntity when login is successful', () async {
      // Arrange
      when(() => mockAuthRepository.loginWithEmailPassword(
        email: testEmail,
        password: testPassword,
      )).thenAnswer((_) async => const Right(testUser));

      // Act
      final result = await loginUseCase(LoginParams(
        email: testEmail,
        password: testPassword,
      ));

      // Assert
      expect(result.isRight(), isTrue);
      expect(result.getOrElse((l) => throw l), testUser);
      verify(() => mockAuthRepository.loginWithEmailPassword(
        email: testEmail,
        password: testPassword,
      )).called(1);
    });

    test('should return ServerFailure when login fails', () async {
      // Arrange
      const failure = ServerFailure('Invalid credentials');
      when(() => mockAuthRepository.loginWithEmailPassword(
        email: testEmail,
        password: testPassword,
      )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await loginUseCase(LoginParams(
        email: testEmail,
        password: testPassword,
      ));

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l.message, 'Invalid credentials'),
        (r) => fail('Should have returned Left'),
      );
    });

    test('should pass correct parameters to repository', () async {
      // Arrange
      const customEmail = 'custom@test.com';
      const customPassword = 'customPass!@#';
      
      when(() => mockAuthRepository.loginWithEmailPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => const Right(testUser));

      // Act
      await loginUseCase(LoginParams(
        email: customEmail,
        password: customPassword,
      ));

      // Assert
      verify(() => mockAuthRepository.loginWithEmailPassword(
        email: customEmail,
        password: customPassword,
      )).called(1);
    });

    test('should return admin user when admin logs in', () async {
      // Arrange
      const adminUser = UserEntity(
        id: 'admin-123',
        email: 'admin@example.com',
        role: UserRole.admin,
        organizationId: 'org-1',
      );
      
      when(() => mockAuthRepository.loginWithEmailPassword(
        email: 'admin@example.com',
        password: testPassword,
      )).thenAnswer((_) async => const Right(adminUser));

      // Act
      final result = await loginUseCase(LoginParams(
        email: 'admin@example.com',
        password: testPassword,
      ));

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should have returned Right'),
        (r) => expect(r.role, UserRole.admin),
      );
    });

    test('should handle network errors gracefully', () async {
      // Arrange
      const failure = ServerFailure('Network error');
      when(() => mockAuthRepository.loginWithEmailPassword(
        email: testEmail,
        password: testPassword,
      )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await loginUseCase(LoginParams(
        email: testEmail,
        password: testPassword,
      ));

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<ServerFailure>()),
        (r) => fail('Should have returned Left'),
      );
    });
  });

  group('LoginParams', () {
    test('should store email and password correctly', () {
      const email = 'test@test.com';
      const password = 'pass123';
      
      final params = LoginParams(email: email, password: password);
      
      expect(params.email, email);
      expect(params.password, password);
    });
  });
}
