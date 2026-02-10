import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:indoor_navigation_system/features/auth/domain/usecases/signup_usecase.dart';
import 'package:indoor_navigation_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:indoor_navigation_system/features/auth/domain/entities/user_entity.dart';
import 'package:indoor_navigation_system/core/errors/failure.dart';

// Mock class
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignUpUseCase signUpUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    signUpUseCase = SignUpUseCase(mockAuthRepository);
  });

  group('SignUpUseCase', () {
    const testEmail = 'newuser@example.com';
    const testPassword = 'securePassword123!';
    const testOrgId = 'org-123';
    const testUser = UserEntity(
      id: 'new-user-123',
      email: testEmail,
      role: UserRole.user,
      organizationId: testOrgId,
    );

    test('should return UserEntity when signup is successful', () async {
      // Arrange
      when(() => mockAuthRepository.signUp(
        email: testEmail,
        password: testPassword,
        organizationId: testOrgId,
      )).thenAnswer((_) async => const Right(testUser));

      // Act
      final result = await signUpUseCase(SignUpParams(
        email: testEmail,
        password: testPassword,
        organizationId: testOrgId,
      ));

      // Assert
      expect(result.isRight(), isTrue);
      expect(result.getOrElse((l) => throw l), testUser);
      verify(() => mockAuthRepository.signUp(
        email: testEmail,
        password: testPassword,
        organizationId: testOrgId,
      )).called(1);
    });

    test('should return ServerFailure when email already exists', () async {
      // Arrange
      const failure = ServerFailure('Email already in use');
      when(() => mockAuthRepository.signUp(
        email: testEmail,
        password: testPassword,
        organizationId: testOrgId,
      )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await signUpUseCase(SignUpParams(
        email: testEmail,
        password: testPassword,
        organizationId: testOrgId,
      ));

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l.message, 'Email already in use'),
        (r) => fail('Should have returned Left'),
      );
    });

    test('should return failure for weak password', () async {
      // Arrange
      const failure = ServerFailure('Password is too weak');
      when(() => mockAuthRepository.signUp(
        email: testEmail,
        password: '123',
        organizationId: testOrgId,
      )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await signUpUseCase(SignUpParams(
        email: testEmail,
        password: '123',
        organizationId: testOrgId,
      ));

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l.message, contains('weak')),
        (r) => fail('Should have returned Left'),
      );
    });

    test('should return failure for invalid email format', () async {
      // Arrange
      const failure = ServerFailure('Invalid email format');
      when(() => mockAuthRepository.signUp(
        email: 'invalid-email',
        password: testPassword,
        organizationId: testOrgId,
      )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await signUpUseCase(SignUpParams(
        email: 'invalid-email',
        password: testPassword,
        organizationId: testOrgId,
      ));

      // Assert
      expect(result.isLeft(), isTrue);
    });

    test('should pass organization ID correctly', () async {
      // Arrange
      const customOrgId = 'custom-organization';
      when(() => mockAuthRepository.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        organizationId: any(named: 'organizationId'),
      )).thenAnswer((_) async => Right(testUser.copyWith(organizationId: customOrgId)));

      // Act
      await signUpUseCase(SignUpParams(
        email: testEmail,
        password: testPassword,
        organizationId: customOrgId,
      ));

      // Assert
      verify(() => mockAuthRepository.signUp(
        email: testEmail,
        password: testPassword,
        organizationId: customOrgId,
      )).called(1);
    });

    test('new user should have user role by default', () async {
      // Arrange
      when(() => mockAuthRepository.signUp(
        email: testEmail,
        password: testPassword,
        organizationId: testOrgId,
      )).thenAnswer((_) async => const Right(testUser));

      // Act
      final result = await signUpUseCase(SignUpParams(
        email: testEmail,
        password: testPassword,
        organizationId: testOrgId,
      ));

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should have returned Right'),
        (r) => expect(r.role, UserRole.user),
      );
    });
  });

  group('SignUpParams', () {
    test('should store all parameters correctly', () {
      const email = 'test@test.com';
      const password = 'pass123';
      const orgId = 'org-1';
      
      final params = SignUpParams(
        email: email, 
        password: password,
        organizationId: orgId,
      );
      
      expect(params.email, email);
      expect(params.password, password);
      expect(params.organizationId, orgId);
    });
  });
}

// Extension for UserEntity to support copyWith
extension UserEntityCopyWith on UserEntity {
  UserEntity copyWith({
    String? id,
    String? email,
    UserRole? role,
    String? organizationId,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      organizationId: organizationId ?? this.organizationId,
    );
  }
}
