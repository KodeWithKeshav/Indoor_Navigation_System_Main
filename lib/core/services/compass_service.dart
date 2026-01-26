import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  void setHeading(double heading) {
    _isOverridden = true;
    state = heading;
  }

  void enableLive() {
    _isOverridden = false;
  }
}

final compassProvider = NotifierProvider<CompassNotifier, double?>(CompassNotifier.new);

