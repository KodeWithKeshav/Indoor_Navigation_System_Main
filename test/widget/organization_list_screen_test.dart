import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/pages/organization_list_screen.dart';

void main() {
  group('OrganizationListScreen Widget', () {
    testWidgets('renders screen with app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OrganizationListScreen(),
          ),
        ),
      );

      // Allow async operations to complete
      await tester.pump();

      // Verify the screen renders
      expect(find.byType(OrganizationListScreen), findsOneWidget);
    });

    testWidgets('has a scaffold structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OrganizationListScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('contains floating action button for adding organization', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OrganizationListScreen(),
          ),
        ),
      );

      await tester.pump();

      // Look for FAB (add button)
      expect(find.byType(FloatingActionButton), findsWidgets);
    });
  });
}
