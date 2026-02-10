import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/core/errors/failure.dart';

void main() {
  test('Failure equality compares message', () {
    const a = ServerFailure('oops');
    const b = ServerFailure('oops');
    const c = CacheFailure('nope');

    expect(a, b);
    expect(a == c, isFalse);
  });
}
