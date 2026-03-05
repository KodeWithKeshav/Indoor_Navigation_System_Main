import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/core/errors/failure.dart';
import 'package:indoor_navigation_system/core/usecase/usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/organization.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/get_organizations_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/providers/admin_map_providers.dart';
import 'package:indoor_navigation_system/features/auth/domain/entities/user_entity.dart';
import 'package:indoor_navigation_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:indoor_navigation_system/features/auth/presentation/providers/auth_providers.dart';
import 'package:indoor_navigation_system/features/navigation/presentation/pages/user_profile_screen.dart';

class MockAuthRepository extends Fake implements AuthRepository {
  @override
  Future<Either<Failure, void>> updateUserOrganization({
    required String uid,
    required String organizationId,
  }) async {
    return const Right(null);
  }
}

class MockGetOrganizationsUseCase extends Fake
    implements GetOrganizationsUseCase {
  @override
  Future<Either<Failure, List<Organization>>> call(NoParams params) async {
    return const Right([
      Organization(id: 'org1', name: 'Org 1', description: 'Desc 1'),
      Organization(id: 'org2', name: 'Org 2', description: 'Desc 2'),
    ]);
  }
}

void main() {
  testWidgets(
    'UserProfileScreen updates organization ID immediately after change',
    (tester) async {
      final authRepo = MockAuthRepository();
      final getOrgs = MockGetOrganizationsUseCase();

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          getOrganizationsUseCaseProvider.overrideWithValue(getOrgs),
        ],
      );

      // Set initial user
      final initialUser = const UserEntity(
        id: '1',
        email: 'test@example.com',
        role: UserRole.user,
        organizationId: 'org1',
      );
      container.read(currentUserProvider.notifier).setUser(initialUser);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: UserProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial org
      expect(find.text('org1'), findsOneWidget);

      // Open dialog
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      // Select new org
      await tester.tap(find.text('Org 2'));
      await tester.pumpAndSettle();

      // Verify new org is shown
      // This expects 'org2' to be visible in the profile screen
      expect(find.text('org2'), findsOneWidget);

      // Cleanup
      container.dispose();
    },
  );
}
