import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/core/errors/failure.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/campus_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/pages/campus_connections_screen.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/providers/admin_map_providers.dart';
import 'package:indoor_navigation_system/features/auth/presentation/providers/auth_providers.dart';
import 'package:indoor_navigation_system/features/auth/domain/entities/user_entity.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/manage_campus_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/repositories/admin_map_repository.dart';

// Fakes
class FakeAdminMapRepository extends Fake implements AdminMapRepository {}

class FakeAddCampusConnectionUseCase extends AddCampusConnectionUseCase {
  FakeAddCampusConnectionUseCase() : super(FakeAdminMapRepository());
  @override
  Future<Either<Failure, void>> call(AddCampusConnectionParams params) async => const Right(null);
}

class FakeDeleteCampusConnectionUseCase extends DeleteCampusConnectionUseCase {
  FakeDeleteCampusConnectionUseCase() : super(FakeAdminMapRepository());
  @override
  Future<Either<Failure, void>> call(String params) async => const Right(null);
}

class MockCurrentUserNotifier extends CurrentUserNotifier {
  final UserEntity? initialState;
  MockCurrentUserNotifier(this.initialState);

  @override
  UserEntity? build() => initialState;
}

void main() {
  group('CampusConnectionsScreen Widget Tests', () {
    testWidgets('renders CampusConnectionsScreen with list', (WidgetTester tester) async {
      // Arrange
      final buildings = [
        Building(id: 'b1', name: 'Building A', description: 'Desc A', organizationId: 'org1'),
        Building(id: 'b2', name: 'Building B', description: 'Desc B', organizationId: 'org1'),
      ];
      final connections = [
        CampusConnection(id: 'cc1', fromBuildingId: 'b1', toBuildingId: 'b2', distance: 50.0),
      ];
      final user = UserEntity(id: 'u1', email: 'test@test.com', role: UserRole.admin, organizationId: 'org1');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(() => MockCurrentUserNotifier(user)), // Correctly override with Notifier
            // Override both possible calls to buildingsProvider
            buildingsProvider(null).overrideWith((ref) => Future.value(buildings)),
            buildingsProvider('org1').overrideWith((ref) => Future.value(buildings)),
            campusConnectionsProvider.overrideWith((ref) => Future.value(connections)),
            
            addCampusConnectionUseCaseProvider.overrideWithValue(FakeAddCampusConnectionUseCase()),
            deleteCampusConnectionUseCaseProvider.overrideWithValue(FakeDeleteCampusConnectionUseCase()),
          ],
          child: const MaterialApp(
            home: CampusConnectionsScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Campus Connections'), findsOneWidget);
      expect(find.text('Link Buildings'), findsOneWidget);
      expect(find.text('Building A  ⟷  Building B'), findsOneWidget);
    });

    testWidgets('shows empty state when no connections', (WidgetTester tester) async {
       // Arrange
      final buildings = [
        Building(id: 'b1', name: 'Building A', description: 'Desc A', organizationId: 'org1'),
      ];
      final user = UserEntity(id: 'u1', email: 'test@test.com', role: UserRole.admin, organizationId: 'org1');

      await tester.pumpWidget(
         ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(() => MockCurrentUserNotifier(user)),
            buildingsProvider(null).overrideWith((ref) => Future.value(buildings)),
            buildingsProvider('org1').overrideWith((ref) => Future.value(buildings)),
            campusConnectionsProvider.overrideWith((ref) => Future.value([])),
             
             addCampusConnectionUseCaseProvider.overrideWithValue(FakeAddCampusConnectionUseCase()),
             deleteCampusConnectionUseCaseProvider.overrideWithValue(FakeDeleteCampusConnectionUseCase()),
          ],
          child: const MaterialApp(
            home: CampusConnectionsScreen(),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('No connections yet.'), findsOneWidget);
    });
  });
}
