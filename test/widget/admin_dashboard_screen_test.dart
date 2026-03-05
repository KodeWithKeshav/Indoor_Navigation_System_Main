import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/core/errors/failure.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/pages/admin_dashboard_screen.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/providers/admin_map_providers.dart';
import 'package:indoor_navigation_system/features/auth/presentation/providers/auth_controller.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/manage_buildings_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/admin_map_usecases.dart'; // Added

import 'package:mockito/mockito.dart';

import 'package:indoor_navigation_system/features/admin_map/domain/repositories/admin_map_repository.dart';

// Fakes
class FakeAdminMapRepository extends Fake implements AdminMapRepository {}

class FakeAuthController extends AuthController {
  FakeAuthController() : super();

  @override
  Future<void> logout(BuildContext context) async {
    // No-op for testing
  }
}

class FakeAddBuildingUseCase extends AddBuildingUseCase {
  FakeAddBuildingUseCase() : super(FakeAdminMapRepository());

  @override
  Future<Either<Failure, void>> call(AddBuildingParams params) async {
    return const Right(null);
  }
}

class FakeDeleteBuildingUseCase extends DeleteBuildingUseCase {
  FakeDeleteBuildingUseCase() : super(FakeAdminMapRepository());

  @override
  Future<Either<Failure, void>> call(String params) async {
    return const Right(null);
  }
}

class FakeUpdateBuildingUseCase extends UpdateBuildingUseCase {
  FakeUpdateBuildingUseCase() : super(FakeAdminMapRepository());

  @override
  Future<Either<Failure, void>> call(UpdateBuildingParams params) async {
    return const Right(null);
  }
}

void main() {
  group('AdminDashboardScreen Widget Tests', () {
    testWidgets('renders AdminDashboardScreen with buildings list', (
      WidgetTester tester,
    ) async {
      // Arrange
      final buildings = [
        Building(
          id: 'b1',
          name: 'Building A',
          description: 'Main Building',
          organizationId: 'org1',
        ),
        Building(
          id: 'b2',
          name: 'Building B',
          description: 'Science Block',
          organizationId: 'org1',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            buildingsProvider('org1').overrideWith(
              (ref) => Stream.value(buildings).first.then((value) => value),
            ), // Simulating AsyncValue.data
            authControllerProvider.overrideWith(() => FakeAuthController()),
            addBuildingUseCaseProvider.overrideWithValue(
              FakeAddBuildingUseCase(),
            ),
            deleteBuildingUseCaseProvider.overrideWithValue(
              FakeDeleteBuildingUseCase(),
            ),
            updateBuildingUseCaseProvider.overrideWithValue(
              FakeUpdateBuildingUseCase(),
            ),
          ],
          child: const MaterialApp(
            home: AdminDashboardScreen(organizationId: 'org1'),
          ),
        ),
      );

      // Act
      await tester.pump(
        const Duration(seconds: 2),
      ); // Wait for FutureProvider and animation

      // Assert
      expect(find.text('CAMPUS MAP EDITOR'), findsOneWidget);
      expect(find.text('BUILDING A'), findsOneWidget); // Uppercase in UI
      expect(find.text('BUILDING B'), findsOneWidget);
      expect(find.text('NEW BUILDING'), findsOneWidget); // FAB label
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows empty state when no buildings', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            buildingsProvider('org1').overrideWith((ref) => Future.value([])),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            addBuildingUseCaseProvider.overrideWithValue(
              FakeAddBuildingUseCase(),
            ),
            deleteBuildingUseCaseProvider.overrideWithValue(
              FakeDeleteBuildingUseCase(),
            ),
            updateBuildingUseCaseProvider.overrideWithValue(
              FakeUpdateBuildingUseCase(),
            ),
          ],
          child: const MaterialApp(
            home: AdminDashboardScreen(organizationId: 'org1'),
          ),
        ),
      );

      // Act
      await tester.pump(const Duration(seconds: 2));

      // Assert
      expect(find.text('NO STRUCTURES DETECTED'), findsOneWidget);
      expect(find.text('INITIALIZE FIRST BUILDING'), findsOneWidget);
    });

    testWidgets('opens drawer', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            buildingsProvider('org1').overrideWith((ref) => Future.value([])),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            addBuildingUseCaseProvider.overrideWithValue(
              FakeAddBuildingUseCase(),
            ),
            deleteBuildingUseCaseProvider.overrideWithValue(
              FakeDeleteBuildingUseCase(),
            ),
            updateBuildingUseCaseProvider.overrideWithValue(
              FakeUpdateBuildingUseCase(),
            ),
          ],
          child: const MaterialApp(
            home: AdminDashboardScreen(organizationId: 'org1'),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Act
      await tester.tap(find.byIcon(Icons.menu)); // Default drawer icon
      await tester.pump(); // Start animation
      await tester.pump(const Duration(seconds: 1)); // Wait for drawer to open

      // Assert
      expect(find.text('ADMIN CONSOLE'), findsOneWidget);
      expect(find.text('ACCESS LEVEL: ROOT'), findsOneWidget);
    });
  });
}
