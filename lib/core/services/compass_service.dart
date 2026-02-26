import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the current platform supports a real hardware compass.
bool get isMobilePlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
         defaultTargetPlatform == TargetPlatform.iOS;
}

/// Manages the device's compass heading.
///
/// On mobile: uses the hardware compass via FlutterCompass.
/// On desktop/web: stays in manual/simulation mode (user can set heading via slider).
class CompassNotifier extends Notifier<double?> {
  StreamSubscription? _subscription;
  bool _isOverridden = false;

  @override
  double? build() {
    if (isMobilePlatform) {
      // On mobile, start listening to the actual hardware compass
      _subscription = FlutterCompass.events?.listen((event) {
        if (!_isOverridden) {
          state = event.heading;
        }
      });
    } else {
      // On desktop/web, default to 0° (North) for simulation
      state = 0.0;
    }

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return isMobilePlatform ? null : 0.0;
  }

  /// Manually sets the heading, disabling live updates.
  void setHeading(double heading) {
    _isOverridden = true;
    state = heading;
  }

  /// Re-enables live compass updates from the device sensors (mobile only).
  void enableLive() {
    _isOverridden = false;
    if (!isMobilePlatform) {
      state = 0.0; // Reset to North on desktop
    }
  }

  /// Whether the compass is using real hardware sensors.
  bool get isLiveCompass => isMobilePlatform && !_isOverridden;
}

final compassProvider = NotifierProvider<CompassNotifier, double?>(CompassNotifier.new);
