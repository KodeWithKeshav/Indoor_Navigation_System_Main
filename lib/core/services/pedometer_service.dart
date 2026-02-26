import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Service that uses the device accelerometer to detect steps and estimate
/// distance walked. Only works on mobile (Android/iOS).
///
/// Uses a peak-detection algorithm on the accelerometer magnitude to count steps,
/// then multiplies by an average step length to estimate distance.
class PedometerService {
  static const double _stepLength = 0.7; // Average step length in meters
  static const double _stepThreshold = 12.0; // Acceleration magnitude threshold
  static const Duration _stepCooldown = Duration(milliseconds: 350); // Min time between steps

  StreamSubscription? _accelSubscription;
  final _distanceController = StreamController<double>.broadcast();
  
  double _totalDistance = 0.0;
  int _stepCount = 0;
  DateTime _lastStepTime = DateTime.now();
  bool _wasBelowThreshold = true;
  bool _isTracking = false;

  /// Stream of cumulative distance walked in meters since last reset.
  Stream<double> get distanceStream => _distanceController.stream;

  /// Current total distance walked since last reset.
  double get totalDistance => _totalDistance;

  /// Current step count since last reset.
  int get stepCount => _stepCount;

  /// Whether the pedometer is actively tracking steps.
  bool get isTracking => _isTracking;

  /// Returns true if running on a mobile platform that supports accelerometer.
  static bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
           defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Start tracking steps using the accelerometer.
  void startTracking() {
    if (!isSupported || _isTracking) return;

    _isTracking = true;
    _accelSubscription = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen(_onAccelerometerData);
    
    debugPrint('🦶 Pedometer: Started tracking');
  }

  /// Stop tracking steps.
  void stopTracking() {
    _accelSubscription?.cancel();
    _accelSubscription = null;
    _isTracking = false;
    debugPrint('🦶 Pedometer: Stopped tracking');
  }

  /// Reset the distance and step counters (e.g., when moving to a new nav step).
  void resetDistance() {
    _totalDistance = 0.0;
    _stepCount = 0;
    _wasBelowThreshold = true;
    debugPrint('🦶 Pedometer: Distance reset');
  }

  void _onAccelerometerData(UserAccelerometerEvent event) {
    // Calculate acceleration magnitude (gravity-free from UserAccelerometer)
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    final now = DateTime.now();

    // Peak detection: detect when magnitude crosses threshold upward
    if (magnitude > _stepThreshold && _wasBelowThreshold) {
      final elapsed = now.difference(_lastStepTime);
      if (elapsed > _stepCooldown) {
        _stepCount++;
        _totalDistance += _stepLength;
        _lastStepTime = now;
        _distanceController.add(_totalDistance);
      }
      _wasBelowThreshold = false;
    } else if (magnitude < _stepThreshold * 0.7) {
      _wasBelowThreshold = true;
    }
  }

  /// Clean up resources.
  void dispose() {
    stopTracking();
    _distanceController.close();
  }
}

final pedometerServiceProvider = Provider<PedometerService>((ref) {
  final service = PedometerService();
  ref.onDispose(() => service.dispose());
  return service;
});
