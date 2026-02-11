import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:indoor_navigation_system/core/errors/failure.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/pages/floor_detail_screen.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/providers/admin_map_providers.dart';
import 'package:indoor_navigation_system/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:indoor_navigation_system/core/services/compass_service.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/admin_map_usecases.dart'; // Correct import
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/delete_room_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/update_room_usecase.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/usecases/add_corridor_usecase.dart';
import 'package:indoor_navigation_system/core/services/graph_service.dart';
import 'package:indoor_navigation_system/features/auth/presentation/providers/auth_controller.dart'; // Added for override

import 'package:indoor_navigation_system/features/admin_map/domain/repositories/admin_map_repository.dart';

// Fakes
class FakeAdminMapRepository extends Fake implements AdminMapRepository {}

class FakeGraphService extends GraphService {
  FakeGraphService(super.repo);
  @override
  void markDirty() {}
}

class FakeAddRoomUseCase extends AddRoomUseCase {
  FakeAddRoomUseCase() : super(FakeAdminMapRepository());
  @override
  Future<Either<Failure, void>> call(AddRoomParams params) async => const Right(null);
}

class FakeDeleteRoomUseCase extends DeleteRoomUseCase {
  FakeDeleteRoomUseCase() : super(FakeAdminMapRepository());
  @override
  Future<Either<Failure, void>> call(DeleteRoomParams params) async => const Right(null);
}

class FakeUpdateRoomUseCase extends UpdateRoomUseCase {
  FakeUpdateRoomUseCase() : super(FakeAdminMapRepository());
  @override
  Future<Either<Failure, void>> call(UpdateRoomUseParams params) async => const Right(null);
}

class FakeAddCorridorUseCase extends AddCorridorUseCase {
  FakeAddCorridorUseCase() : super(FakeAdminMapRepository());
  @override
  Future<Either<Failure, void>> call(AddCorridorParams params) async => const Right(null);
}

// Mock Navigation Notifier
class MockNavigationNotifier extends NavigationNotifier {
  MockNavigationNotifier() : super(); // No args

  @override
  NavigationState build() {
    return NavigationState(); // Not const
  }
}

class FakeAuthController extends AuthController {
  FakeAuthController() : super();
  @override
  Future<void> logout(BuildContext context) async {}
}
// Mock Compass
class MockCompassNotifier extends CompassNotifier {
  @override
  double? build() => 0.0;
}


void main() {
  group('FloorDetailScreen Widget Tests', () {
    testWidgets('renders FloorDetailScreen with rooms and corridors', (WidgetTester tester) async {
      // Arrange
      final rooms = [
        Room(id: 'r1', floorId: 'f1', name: 'Room 101', x: 100, y: 100, type: RoomType.room),
        Room(id: 'r2', floorId: 'f1', name: 'Room 102', x: 200, y: 200, type: RoomType.room),
      ];
      final corridors = [
        Corridor(id: 'c1', floorId: 'f1', startRoomId: 'r1', endRoomId: 'r2', distance: 10),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomsProvider(const FloorParams('b1', 'f1')).overrideWith((ref) => Stream.value(rooms).first.then((value) => value)),
            corridorsProvider(const FloorParams('b1', 'f1')).overrideWith((ref) => Stream.value(corridors).first.then((value) => value)),
            buildingsProvider('org1').overrideWith((ref) => Future.value([])),
            
            navigationProvider.overrideWith(() => MockNavigationNotifier()),
            compassProvider.overrideWith(() => MockCompassNotifier()),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            
            addRoomUseCaseProvider.overrideWithValue(FakeAddRoomUseCase()),
            deleteRoomUseCaseProvider.overrideWithValue(FakeDeleteRoomUseCase()),
            updateRoomUseCaseProvider.overrideWithValue(FakeUpdateRoomUseCase()),
            addCorridorUseCaseProvider.overrideWithValue(FakeAddCorridorUseCase()),
            graphServiceProvider.overrideWith((ref) => FakeGraphService(null as dynamic)),
          ],
          child: const MaterialApp(
            home: FloorDetailScreen(buildingId: 'b1', floorId: 'f1', floorName: 'First Floor'),
          ),
        ),
      );

      // Act
      await tester.pump(const Duration(seconds: 2));

      // Assert
      expect(find.text('MAP EDITOR'), findsOneWidget);
      expect(find.text('Room 101'), findsOneWidget);
      expect(find.text('Room 102'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsWidgets);
    });

    testWidgets('shows empty state', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
             roomsProvider(const FloorParams('b1', 'f1')).overrideWith((ref) => Future.value([])),
             corridorsProvider(const FloorParams('b1', 'f1')).overrideWith((ref) => Future.value([])),
             buildingsProvider('org1').overrideWith((ref) => Future.value([])),

            navigationProvider.overrideWith(() => MockNavigationNotifier()),
            compassProvider.overrideWith(() => MockCompassNotifier()),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            
            addRoomUseCaseProvider.overrideWithValue(FakeAddRoomUseCase()),
            deleteRoomUseCaseProvider.overrideWithValue(FakeDeleteRoomUseCase()),
            updateRoomUseCaseProvider.overrideWithValue(FakeUpdateRoomUseCase()),
            addCorridorUseCaseProvider.overrideWithValue(FakeAddCorridorUseCase()),
            graphServiceProvider.overrideWith((ref) => FakeGraphService(null as dynamic)),
          ],
          child: const MaterialApp(
            home: FloorDetailScreen(buildingId: 'b1', floorId: 'f1', floorName: 'Empty Floor'),
          ),
        ),
      );

      // Act
      await tester.pump(const Duration(seconds: 2));

      // Assert
      // We still expect the scaffold and editor UI to be there, just no nodes.
      // There isn't an explicit "No Rooms" text logic in the build method unless error, it just renders empty stack.
      expect(find.text('MAP EDITOR'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });
  });
}
