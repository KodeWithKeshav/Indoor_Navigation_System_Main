import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:indoor_navigation_system/core/services/compass_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fused device orientation combining compass heading + gyroscope smoothing.
class DeviceOrientationData {
  final double heading; // 0..360 degrees (north-referenced)
  final double pitch; // -90..90 degrees (phone tilt up/down)

  const DeviceOrientationData({required this.heading, required this.pitch});
}

/// Service that fuses compass heading with gyroscope data for smooth,
/// low-latency device orientation suitable for AR overlay rendering.
///
/// Uses an exponential low-pass filter (EMA) to reduce compass jitter
/// while keeping responsiveness. Gyroscope pitch is used to shift the
/// arrow anchor point vertically based on phone tilt.
class DeviceOrientationService {
  final Ref ref;

  StreamSubscription? _gyroSubscription;
  StreamSubscription? _compassSubscription;

  double _smoothedHeading = 0.0;
  double _smoothedPitch = 0.0;

  /// EMA smoothing factor — lower = smoother, higher = more responsive.
  static const double _headingAlpha = 0.15;
  static const double _pitchAlpha = 0.1;

  final _controller = StreamController<DeviceOrientationData>.broadcast();

  /// Stream of fused orientation data.
  Stream<DeviceOrientationData> get orientationStream => _controller.stream;

  /// Current heading (most recent value).
  double get currentHeading => _smoothedHeading;

  /// Current pitch (most recent value).
  double get currentPitch => _smoothedPitch;

  DeviceOrientationService(this.ref);

  /// Start listening to compass and gyroscope sensors.
  void start() {
    _startCompassListening();
    _startGyroListening();
  }

  void _startCompassListening() {
    // Poll compass at ~30 Hz via a periodic check of the Riverpod provider
    _compassSubscription?.cancel();
    _compassSubscription = Stream.periodic(const Duration(milliseconds: 33))
        .listen((_) {
          final heading = ref.read(compassProvider);
          if (heading != null) {
            _smoothedHeading = _circularEma(
              _smoothedHeading,
              heading,
              _headingAlpha,
            );
            _emit();
          }
        });
  }

  void _startGyroListening() {
    _gyroSubscription?.cancel();
    if (!isMobilePlatform) {
      _smoothedPitch = 0.0;
      return;
    }

    _gyroSubscription =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 33),
        ).listen((event) {
          // Pitch from accelerometer: angle of phone tilt from vertical.
          // When phone is vertical (portrait), z ≈ 0, y ≈ -9.8.
          // When phone is horizontal face-up, y ≈ 0, z ≈ -9.8.
          final rawPitch = atan2(event.z, event.y) * (180 / pi);
          _smoothedPitch =
              _smoothedPitch * (1 - _pitchAlpha) + rawPitch * _pitchAlpha;
          _smoothedPitch = _smoothedPitch.clamp(-90.0, 90.0);
          _emit();
        });
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(
        DeviceOrientationData(heading: _smoothedHeading, pitch: _smoothedPitch),
      );
    }
  }

  /// Circular exponential moving average for heading values that wrap at 360°.
  double _circularEma(double current, double newValue, double alpha) {
    double diff = newValue - current;
    // Normalize to [-180, 180]
    while (diff > 180) diff -= 360;
    while (diff <= -180) diff += 360;
    return (current + alpha * diff) % 360;
  }

  /// Stop all sensor listeners and close the stream.
  void dispose() {
    _gyroSubscription?.cancel();
    _compassSubscription?.cancel();
    _controller.close();
  }
}

/// Provider for DeviceOrientationService — auto-disposed when no longer used.
final deviceOrientationServiceProvider =
    Provider.autoDispose<DeviceOrientationService>((ref) {
      final service = DeviceOrientationService(ref);
      service.start();
      ref.onDispose(() => service.dispose());
      return service;
    });
