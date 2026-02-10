import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the device's compass heading.
///
/// Provides a stream of heading values and allows for manual override
/// (useful for testing or when user manually rotates map).
class CompassNotifier extends Notifier<double?> {
  StreamSubscription? _subscription;
  bool _isOverridden = false;

  @override
  double? build() {
    _subscription = FlutterCompass.events?.listen((event) {
      if (!_isOverridden) {
        state = event.heading;
      }
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return null;
  }

  /// Manually sets the heading, disabling live updates.
  void setHeading(double heading) {
    _isOverridden = true;
    state = heading;
  }

  /// Re-enables live compass updates from the device sensors.
  void enableLive() {
    _isOverridden = false;
  }
}

final compassProvider = NotifierProvider<CompassNotifier, double?>(CompassNotifier.new);

