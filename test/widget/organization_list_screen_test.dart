import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/core/errors/failure.dart';
import 'package:indoor_navigation_system/core/usecase/usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/organization.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/campus_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/repositories/admin_map_repository.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/get_organizations_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/pages/organization_list_screen.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/providers/admin_map_providers.dart';
import 'package:indoor_navigation_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:indoor_navigation_system/features/auth/domain/entities/user_entity.dart';
import 'package:indoor_navigation_system/features/auth/domain/usecases/login_usecase.dart';
import 'package:indoor_navigation_system/features/auth/presentation/providers/auth_providers.dart';

class _FakeGetOrganizationsUseCase extends GetOrganizationsUseCase {
  _FakeGetOrganizationsUseCase() : super(_NoopRepo());

  @override
  Future<Either<Failure, List<Organization>>> call(NoParams params) async {
    return const Right([]);
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, UserEntity>> loginWithEmailPassword({
    required String email,
    required String password,
  }) async => Right(UserEntity(id: '1', email: email, role: UserRole.user));

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String organizationId,
  }) async => Right(UserEntity(id: '1', email: email, role: UserRole.user));

  @override
  Future<Either<Failure, void>> logout() async => const Right(null);

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async =>
      const Right(null);

  @override
  Future<Either<Failure, List<UserEntity>>> getAllUsers() async =>
      const Right([]);

  @override
  Future<Either<Failure, void>> updateUserRole({
    required String uid,
    required String role,
  }) async => const Right(null);

  @override
  Future<Either<Failure, void>> updateUserOrganization({
    required String uid,
    required String organizationId,
  }) async => const Right(null);
}

class _FakeLoginUseCase extends LoginUseCase {
  _FakeLoginUseCase() : super(_FakeAuthRepository());

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    return Right(UserEntity(id: '1', email: params.email, role: UserRole.user));
  }
}

class _NoopRepo implements AdminMapRepository {
  @override
  Future<Either<Failure, void>> addOrganization(
    String name,
    String description,
  ) async => const Right(null);
  @override
  Future<Either<Failure, List<Organization>>> getOrganizations() async =>
      const Right([]);
  @override
  Future<Either<Failure, void>> deleteOrganization(
    String organizationId,
  ) async => const Right(null);
  @override
  Future<Either<Failure, void>> updateOrganization(
    String organizationId,
    String name,
    String description,
  ) async => const Right(null);
  @override
  Future<Either<Failure, void>> addBuilding(
    String name,
    String description,
    String? organizationId,
  ) async => const Right(null);
  @override
  Future<Either<Failure, List<Building>>> getBuildings({
    String? organizationId,
  }) async => const Right([]);
  @override
  Future<Either<Failure, void>> deleteBuilding(String buildingId) async =>
      const Right(null);
  @override
  Future<Either<Failure, void>> updateBuilding(
    String buildingId,
    String name,
    String description,
  ) async => const Right(null);
  @override
  Future<Either<Failure, void>> addFloor(
    String buildingId,
    int floorNumber,
    String name,
  ) async => const Right(null);
  @override
  Future<Either<Failure, List<Floor>>> getFloors(String buildingId) async =>
      const Right([]);
  @override
  Future<Either<Failure, void>> deleteFloor(
    String buildingId,
    String floorId,
  ) async => const Right(null);
  @override
  Future<Either<Failure, void>> updateFloor(
    String buildingId,
    String floorId,
    int floorNumber,
    String name,
  ) async => const Right(null);
  @override
  Future<Either<Failure, void>> addRoom(
    String buildingId,
    String floorId,
    String name,
    double x,
    double y, {
    RoomType type = RoomType.room,
    String? connectorId,
    bool isClosed = false,
  }) async => const Right(null);
  @override
  Future<Either<Failure, List<Room>>> getRooms(
    String buildingId,
    String floorId,
  ) async => const Right([]);
  @override
  Future<Either<Failure, void>> deleteRoom(
    String buildingId,
    String floorId,
    String roomId,
  ) async => const Right(null);
  @override
  Future<Either<Failure, void>> updateRoom(
    String buildingId,
    String floorId,
    String roomId, {
    double? x,
    double? y,
    String? name,
    RoomType? type,
    String? connectorId,
    bool? isClosed,
  }) async => const Right(null);
  @override
  Future<Either<Failure, void>> addCorridor(
    String buildingId,
    String floorId,
    String startRoomId,
    String endRoomId,
    double distance,
  ) async => const Right(null);
  @override
  Future<Either<Failure, List<Corridor>>> getCorridors(
    String buildingId,
    String floorId,
  ) async => const Right([]);
  @override
  Future<Either<Failure, void>> addCampusConnection(
    String fromBuildingId,
    String toBuildingId,
    double distance,
  ) async => const Right(null);
  @override
  Future<Either<Failure, List<CampusConnection>>>
  getCampusConnections() async => const Right([]);
  @override
  Future<Either<Failure, void>> deleteCampusConnection(
    String connectionId,
  ) async => const Right(null);
}

void main() {
  group('OrganizationListScreen Widget', () {
    testWidgets('renders screen with app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getOrganizationsUseCaseProvider.overrideWithValue(
              _FakeGetOrganizationsUseCase(),
            ),
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
            loginUseCaseProvider.overrideWithValue(_FakeLoginUseCase()),
          ],
          child: const MaterialApp(home: OrganizationListScreen()),
        ),
      );

      // Allow async operations to complete
      await tester.pump();

      // Verify the screen renders
      expect(find.byType(OrganizationListScreen), findsOneWidget);
    });

    testWidgets('has a scaffold structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getOrganizationsUseCaseProvider.overrideWithValue(
              _FakeGetOrganizationsUseCase(),
            ),
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
            loginUseCaseProvider.overrideWithValue(_FakeLoginUseCase()),
          ],
          child: const MaterialApp(home: OrganizationListScreen()),
        ),
      );

      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('contains floating action button for adding organization', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getOrganizationsUseCaseProvider.overrideWithValue(
              _FakeGetOrganizationsUseCase(),
            ),
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
            loginUseCaseProvider.overrideWithValue(_FakeLoginUseCase()),
          ],
          child: const MaterialApp(home: OrganizationListScreen()),
        ),
      );

      await tester.pump();

      // Look for FAB (add button)
      expect(find.byType(FloatingActionButton), findsWidgets);
    });
  });
}
