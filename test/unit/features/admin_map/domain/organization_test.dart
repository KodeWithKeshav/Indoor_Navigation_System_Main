import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/organization.dart';

void main() {
  test('Organization supports equality', () {
    const a = Organization(id: '1', name: 'Org', description: 'Desc');
    const b = Organization(id: '1', name: 'Org', description: 'Desc');
    const c = Organization(id: '2', name: 'Other', description: 'Other');

    expect(a, b);
    expect(a == c, isFalse);
  });
}
