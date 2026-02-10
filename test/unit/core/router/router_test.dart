import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:indoor_navigation_system/core/router/router.dart';
import 'package:indoor_navigation_system/features/auth/presentation/providers/auth_providers.dart';

void main() {
  test('routerProvider builds GoRouter with overrides', () {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        userProfileProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    expect(router, isA<GoRouter>());
  });
}
