
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/navigation/presentation/widgets/trip_planner_widget.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/providers/admin_map_providers.dart';
import 'package:indoor_navigation_system/features/auth/presentation/providers/auth_providers.dart';
import 'package:indoor_navigation_system/core/services/graph_service.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock Services
class MockGraphService extends Mock implements GraphService {
  @override
  List<Room> get allRooms => [
    const Room(id: 'r1', floorId: 'f1', name: 'Room 101', x: 0, y: 0),
    const Room(id: 'r2', floorId: 'f1', name: 'Room 102', x: 10, y: 10),
  ];
  
  @override
  String getBuildingIdForFloor(String floorId) => 'b1';
}

void main() {
  late MockGraphService mockGraphService;

  setUp(() {
    mockGraphService = MockGraphService();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TripPlannerWidget renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          graphServiceProvider.overrideWithValue(mockGraphService),
          // Mock auth/buildings if needed, or rely on empty initial states
          buildingsProvider(null).overrideWith((ref) => [
             const Building(id: 'b1', name: 'Building A', description: ''),
          ]),
          floorsOfBuildingProvider('b1').overrideWith((ref) => [
             const Floor(id: 'f1', buildingId: 'b1', floorNumber: 1, name: 'First Floor'),
          ]),
        ],
        child: const MaterialApp(home: Scaffold(body: TripPlannerWidget())),
      ),
    );

    // Initial State: Building Guide Tab
    expect(find.text('Building Guide'), findsOneWidget);
    expect(find.text('From Building'), findsOneWidget);
    expect(find.text('To Building'), findsOneWidget);

    // Swap Button Exists
    expect(find.byIcon(Icons.swap_vert_circle), findsOneWidget);
  });

  // Note: More detailed interaction tests (Swap logic) are best done with integration tests 
  // or by mocking more complex state, but basic rendering confirms widget structure.
}
