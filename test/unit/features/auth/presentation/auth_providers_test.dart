import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indoor_navigation_system/features/auth/domain/entities/user_entity.dart';
import 'package:indoor_navigation_system/features/auth/presentation/providers/auth_providers.dart';

void main() {
  test('currentUserProvider stores user', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(currentUserProvider), isNull);

    const user = UserEntity(id: 'u1', email: 'u1@example.com', role: UserRole.user);
    container.read(currentUserProvider.notifier).setUser(user);

    expect(container.read(currentUserProvider)?.id, 'u1');
  });
}
