import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/firebase_options.dart';

void main() {
  test('DefaultFirebaseOptions throws on unsupported platforms', () {
    if (kIsWeb) {
      expect(DefaultFirebaseOptions.currentPlatform, isNotNull);
      return;
    }

    final previous = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      expect(
        () => DefaultFirebaseOptions.currentPlatform,
        throwsUnimplementedError,
      );
    } finally {
      debugDefaultTargetPlatformOverride = previous;
    }
  });
}
