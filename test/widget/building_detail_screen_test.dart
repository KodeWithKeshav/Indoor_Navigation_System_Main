import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/core/errors/failure.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/pages/building_detail_screen.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/providers/admin_map_providers.dart';
import 'package:indoor_navigation_system/features/auth/presentation/providers/auth_controller.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/manage_floors_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/admin_map_usecases.dart'; // Added for AddFloor

import 'package:indoor_navigation_system/features/admin_map/domain/repositories/admin_map_repository.dart';

// Fakes
class FakeAdminMapRepository extends Fake implements AdminMapRepository {}

class FakeAuthController extends AuthController {
  FakeAuthController() : super();

  @override
  Future<void> logout(BuildContext context) async {}
}

class FakeAddFloorUseCase extends AddFloorUseCase {
  FakeAddFloorUseCase() : super(FakeAdminMapRepository());

  @override
  Future<Either<Failure, void>> call(AddFloorParams params) async {
    return const Right(null);
  }
}

class FakeUpdateFloorUseCase extends UpdateFloorUseCase {
  FakeUpdateFloorUseCase() : super(FakeAdminMapRepository());

  @override
  Future<Either<Failure, void>> call(UpdateFloorParams params) async {
    return const Right(null);
  }
}

class FakeDeleteFloorUseCase extends DeleteFloorUseCase {
  FakeDeleteFloorUseCase() : super(FakeAdminMapRepository());

  @override
  Future<Either<Failure, void>> call(DeleteFloorParams params) async {
    return const Right(null);
  }
}

void main() {
  group('BuildingDetailScreen Widget Tests', () {
    testWidgets('renders BuildingDetailScreen with floors list', (
      WidgetTester tester,
    ) async {
      // Arrange
      final floors = [
        Floor(id: 'f1', buildingId: 'b1', floorNumber: 1, name: 'First Floor'),
        Floor(id: 'f2', buildingId: 'b1', floorNumber: 2, name: 'Second Floor'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override the family provider with a direct value for the specific building argument
            floorsOfBuildingProvider('b1').overrideWith(
              (ref) => Stream.value(floors).first.then((value) => value),
            ),
            // Also override the local floorsProvider used in the file if it differs,
            // but looking at the file, it uses a local `floorsProvider` that calls `getFloorsUseCase`.
            // The file `building_detail_screen.dart` defines `floorsProvider` on line 13.
            // We need to override THAT one. Since it is top-level in that file, we can import it.
            floorsProvider('b1').overrideWith(
              (ref) => Stream.value(floors).first.then((value) => value),
            ),

            authControllerProvider.overrideWith(() => FakeAuthController()),
            addFloorUseCaseProvider.overrideWithValue(FakeAddFloorUseCase()),
            updateFloorUseCaseProvider.overrideWithValue(
              FakeUpdateFloorUseCase(),
            ),
            deleteFloorUseCaseProvider.overrideWithValue(
              FakeDeleteFloorUseCase(),
            ),
          ],
          child: const MaterialApp(
            home: BuildingDetailScreen(
              buildingId: 'b1',
              buildingName: 'Science Block',
            ),
          ),
        ),
      );

      // Act
      await tester.pump(const Duration(seconds: 2));

      // Assert
      expect(find.text('BUILDING CONFIGURATION'), findsOneWidget);
      expect(find.text('SCIENCE BLOCK'), findsOneWidget); // Uppercase
      expect(find.text('First Floor'.toUpperCase()), findsOneWidget);
      expect(find.text('Second Floor'.toUpperCase()), findsOneWidget);
      expect(find.text('ADD FLOOR'), findsOneWidget);
    });

    testWidgets('shows empty state when no floors', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Note: In the test file, the provider override on line 100 relies on import aliases or context.
            // Ensure we are hitting the right provider.
            floorsProvider('b1').overrideWith((ref) => Future.value([])),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            addFloorUseCaseProvider.overrideWithValue(FakeAddFloorUseCase()),
            updateFloorUseCaseProvider.overrideWithValue(
              FakeUpdateFloorUseCase(),
            ),
            deleteFloorUseCaseProvider.overrideWithValue(
              FakeDeleteFloorUseCase(),
            ),
          ],
          child: const MaterialApp(
            home: BuildingDetailScreen(
              buildingId: 'b1',
              buildingName: 'Empty Building',
            ),
          ),
        ),
      );

      // Act
      await tester.pump(const Duration(seconds: 2));

      // Assert
      expect(find.text('NO FLOORS DETECTED'), findsOneWidget);
    });
  });
}
