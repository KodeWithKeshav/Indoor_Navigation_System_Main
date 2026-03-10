import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/features/auth/domain/entities/user_entity.dart';
import 'package:indoor_navigation_system/features/auth/domain/usecases/signup_usecase.dart';
import 'package:indoor_navigation_system/features/auth/domain/usecases/manage_users_usecase.dart';
import 'package:indoor_navigation_system/features/auth/domain/usecases/update_user_org_usecase.dart';
import '../test_utils/fakes.dart';

void main() {
  group('User Management Integration', () {
    late FakeAuthRepository repo;
    late SignUpUseCase signUpUseCase;
    late ManageUsersUseCase manageUsersUseCase;
    late UpdateUserOrgUseCase updateUserOrgUseCase;

    setUp(() {
      repo = FakeAuthRepository(
        users: [
          const UserEntity(
            id: 'admin-1',
            email: 'admin@test.com',
            role: UserRole.admin,
            organizationId: 'org-1',
          ),
          const UserEntity(
            id: 'user-1',
            email: 'user@test.com',
            role: UserRole.user,
            organizationId: 'org-1',
          ),
        ],
      );
      signUpUseCase = SignUpUseCase(repo);
      manageUsersUseCase = ManageUsersUseCase(repo);
      updateUserOrgUseCase = UpdateUserOrgUseCase(repo);
    });

    test('list all users returns seeded users', () async {
      final result = await manageUsersUseCase.getAllUsers();
      expect(result.isRight(), isTrue);

      final users = result.getRight().getOrElse(() => []);
      expect(users.length, 2);
      expect(users[0].email, 'admin@test.com');
      expect(users[1].email, 'user@test.com');
    });

    test('promote user to admin role', () async {
      // Promote user-1 to admin
      final promoteResult = await manageUsersUseCase.updateUserRole(
        uid: 'user-1',
        role: 'admin',
      );
      expect(promoteResult, const Right(null));

      // Verify the role changed
      final users = (await manageUsersUseCase.getAllUsers())
          .getRight()
          .getOrElse(() => []);
      final promotedUser = users.firstWhere((u) => u.id == 'user-1');
      expect(promotedUser.role, UserRole.admin);
    });

    test('demote admin to user role', () async {
      // admin-1 is already admin, demote to user
      final demoteResult = await manageUsersUseCase.updateUserRole(
        uid: 'admin-1',
        role: 'user',
      );
      expect(demoteResult, const Right(null));

      final users = (await manageUsersUseCase.getAllUsers())
          .getRight()
          .getOrElse(() => []);
      final demotedUser = users.firstWhere((u) => u.id == 'admin-1');
      expect(demotedUser.role, UserRole.user);
    });

    test('assign user to different organization', () async {
      // user-1 is in org-1, move to org-2
      final result = await updateUserOrgUseCase(
        const UpdateUserOrgParams(uid: 'user-1', organizationId: 'org-2'),
      );
      expect(result, const Right(null));

      // Verify the org changed
      final users = (await manageUsersUseCase.getAllUsers())
          .getRight()
          .getOrElse(() => []);
      final updatedUser = users.firstWhere((u) => u.id == 'user-1');
      expect(updatedUser.organizationId, 'org-2');
    });

    test('promote and reassign in sequence', () async {
      // 1. Promote user-1
      await manageUsersUseCase.updateUserRole(uid: 'user-1', role: 'admin');

      // 2. Reassign user-1 to org-2
      await updateUserOrgUseCase(
        const UpdateUserOrgParams(uid: 'user-1', organizationId: 'org-2'),
      );

      // 3. Verify both changes persisted
      final users = (await manageUsersUseCase.getAllUsers())
          .getRight()
          .getOrElse(() => []);
      final user = users.firstWhere((u) => u.id == 'user-1');
      expect(user.role, UserRole.admin);
      expect(user.organizationId, 'org-2');
    });

    test('list users reflects all mutations', () async {
      // Multiple mutations
      await manageUsersUseCase.updateUserRole(uid: 'user-1', role: 'admin');
      await updateUserOrgUseCase(
        const UpdateUserOrgParams(uid: 'admin-1', organizationId: 'org-3'),
      );

      final users = (await manageUsersUseCase.getAllUsers())
          .getRight()
          .getOrElse(() => []);

      // admin-1 should now be in org-3
      final admin1 = users.firstWhere((u) => u.id == 'admin-1');
      expect(admin1.organizationId, 'org-3');

      // user-1 should now be admin
      final user1 = users.firstWhere((u) => u.id == 'user-1');
      expect(user1.role, UserRole.admin);
    });
  });
}
