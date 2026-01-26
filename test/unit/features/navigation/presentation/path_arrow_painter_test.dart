import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/navigation/presentation/widgets/path_arrow_painter.dart';

void main() {
  test('PathArrowPainter shouldRepaint checks list identity', () {
    final rooms = [Room(id: 'r1', floorId: 'f1', name: 'A', x: 0, y: 0)];
    final pathIds = ['r1'];

    final painter = PathArrowPainter(rooms: rooms, pathIds: pathIds);
    final same = PathArrowPainter(rooms: rooms, pathIds: pathIds);
    final different = PathArrowPainter(rooms: rooms, pathIds: ['r1', 'r2']);

    expect(painter.shouldRepaint(same), isFalse);
    expect(painter.shouldRepaint(different), isTrue);
  });
}
