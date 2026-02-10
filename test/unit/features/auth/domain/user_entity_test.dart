import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserEntity', () {
    test('should create UserEntity with required parameters', () {
      const user = UserEntity(
        id: 'user-123',
        email: 'test@example.com',
        role: UserRole.user,
      );

      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.role, UserRole.user);
      expect(user.organizationId, ''); // Default value
    });

    test('should create UserEntity with organization ID', () {
      const user = UserEntity(
        id: 'user-123',
        email: 'test@example.com',
        role: UserRole.user,
        organizationId: 'org-456',
      );

      expect(user.organizationId, 'org-456');
    });

    test('should create admin UserEntity', () {
      const admin = UserEntity(
        id: 'admin-1',
        email: 'admin@example.com',
        role: UserRole.admin,
        organizationId: 'org-1',
      );

      expect(admin.role, UserRole.admin);
    });

    test('should be equal when all properties match', () {
      const user1 = UserEntity(
        id: 'user-123',
        email: 'test@example.com',
        role: UserRole.user,
        organizationId: 'org-1',
      );
      const user2 = UserEntity(
        id: 'user-123',
        email: 'test@example.com',
        role: UserRole.user,
        organizationId: 'org-1',
      );

      expect(user1, equals(user2));
    });

    test('should not be equal when ID differs', () {
      const user1 = UserEntity(
        id: 'user-123',
        email: 'test@example.com',
        role: UserRole.user,
      );
      const user2 = UserEntity(
        id: 'user-456',
        email: 'test@example.com',
        role: UserRole.user,
      );

      expect(user1, isNot(equals(user2)));
    });

    test('should not be equal when email differs', () {
      const user1 = UserEntity(
        id: 'user-123',
        email: 'test1@example.com',
        role: UserRole.user,
      );
      const user2 = UserEntity(
        id: 'user-123',
        email: 'test2@example.com',
        role: UserRole.user,
      );

      expect(user1, isNot(equals(user2)));
    });

    test('should not be equal when role differs', () {
      const user1 = UserEntity(
        id: 'user-123',
        email: 'test@example.com',
        role: UserRole.user,
      );
      const user2 = UserEntity(
        id: 'user-123',
        email: 'test@example.com',
        role: UserRole.admin,
      );

      expect(user1, isNot(equals(user2)));
    });

    test('should not be equal when organizationId differs', () {
      const user1 = UserEntity(
        id: 'user-123',
        email: 'test@example.com',
        role: UserRole.user,
        organizationId: 'org-1',
      );
      const user2 = UserEntity(
        id: 'user-123',
        email: 'test@example.com',
        role: UserRole.user,
        organizationId: 'org-2',
      );

      expect(user1, isNot(equals(user2)));
    });

    test('props should include all properties', () {
      const user = UserEntity(
        id: 'user-123',
        email: 'test@example.com',
        role: UserRole.user,
        organizationId: 'org-1',
      );

      expect(user.props.length, 4);
      expect(user.props, contains('user-123'));
      expect(user.props, contains('test@example.com'));
      expect(user.props, contains(UserRole.user));
      expect(user.props, contains('org-1'));
    });
  });

  group('UserRole Enum', () {
    test('should have admin role', () {
      expect(UserRole.values, contains(UserRole.admin));
    });

    test('should have user role', () {
      expect(UserRole.values, contains(UserRole.user));
    });

    test('should have exactly 2 roles', () {
      expect(UserRole.values.length, 2);
    });
  });
}
