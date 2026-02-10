import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:indoor_navigation_system/core/router/router.dart';
import 'package:indoor_navigation_system/main.dart';

void main() {
  testWidgets('MyApp builds with router override', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(router),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump();
    expect(find.text('Home'), findsOneWidget);
  });
}
