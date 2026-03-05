import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/providers/user_management_controller.dart';
import 'package:indoor_navigation_system/features/auth/domain/entities/user_entity.dart';
import 'package:indoor_navigation_system/features/auth/domain/usecases/manage_users_usecase.dart';
import 'package:indoor_navigation_system/features/auth/presentation/providers/auth_providers.dart';
import '../../../../test_utils/fakes.dart';

void main() {
  test('UserManagementController updates role', () async {
    final repo = FakeAuthRepository(
      users: [
        const UserEntity(
          id: 'u1',
          email: 'u1@example.com',
          role: UserRole.user,
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        manageUsersUseCaseProvider.overrideWithValue(ManageUsersUseCase(repo)),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(userManagementControllerProvider.notifier)
        .updateUserRole('u1', UserRole.admin);

    final users = await container.read(allUsersProvider.future);
    expect(users.first.role, UserRole.admin);
  });
}
