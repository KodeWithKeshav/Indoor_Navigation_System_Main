import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/campus_entities.dart';

void main() {
  test('CampusConnection equality compares fields', () {
    const a = CampusConnection(id: 'c1', fromBuildingId: 'b1', toBuildingId: 'b2', distance: 12.5);
    const b = CampusConnection(id: 'c1', fromBuildingId: 'b1', toBuildingId: 'b2', distance: 12.5);
    const c = CampusConnection(id: 'c2', fromBuildingId: 'b1', toBuildingId: 'b3', distance: 12.5);

    expect(a, b);
    expect(a == c, isFalse);
  });
}
