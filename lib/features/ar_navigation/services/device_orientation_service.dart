import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:indoor_navigation_system/core/services/compass_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fused device orientation combining compass heading + accelerometer pitch.
class DeviceOrientationData {
  final double heading; // 0..360 degrees (north-referenced)
  final double pitch; // -90..90 degrees (phone tilt up/down)

  const DeviceOrientationData({required this.heading, required this.pitch});
}

/// Service that fuses compass heading with accelerometer data for smooth,
/// cross-device orientation suitable for AR overlay rendering.
///
/// Cross-device compatibility fixes:
/// - Adaptive EMA smoothing that adjusts to actual sensor event frequency
/// - Graceful fallback when sensors are unavailable or throw errors
/// - Safe handling of NaN/infinity values from sensors
/// - Accelerometer-based pitch with proper axis handling for all orientations
/// - Compass polling rate that works across device capabilities
class DeviceOrientationService {
  final Ref ref;

  StreamSubscription? _accelSubscription;
  StreamSubscription? _compassSubscription;

  double _smoothedHeading = 0.0;
  double _smoothedPitch = 0.0;

  /// Timestamp tracking for adaptive smoothing.
  DateTime? _lastHeadingUpdate;
  DateTime? _lastPitchUpdate;

  /// Base EMA smoothing factors — adjusted at runtime based on event frequency.
  /// Lower = smoother (less jitter), Higher = more responsive.
  static const double _baseHeadingAlpha = 0.12;
  static const double _basePitchAlpha = 0.08;

  /// Maximum time between sensor events before we treat the next event as "stale"
  /// and apply stronger smoothing to avoid jumps.
  static const int _staleThresholdMs = 200;

  final _controller = StreamController<DeviceOrientationData>.broadcast();

  /// Stream of fused orientation data.
  Stream<DeviceOrientationData> get orientationStream => _controller.stream;

  /// Current heading (most recent value).
  double get currentHeading => _smoothedHeading;

  /// Current pitch (most recent value).
  double get currentPitch => _smoothedPitch;

  DeviceOrientationService(this.ref);

  /// Start listening to compass and accelerometer sensors.
  void start() {
    _startCompassListening();
    _startAccelerometerListening();
  }

  void _startCompassListening() {
    _compassSubscription?.cancel();

    if (!isMobilePlatform) {
      // Desktop/web: no compass, default heading to 0
      _smoothedHeading = 0.0;
      return;
    }

    // Poll compass at ~20 Hz (50ms) — a safe rate that works across devices.
    // Higher rates (33ms/30Hz) can overwhelm slower sensor chips and cause
    // the compass provider to return stale/null values on some Android phones.
    _compassSubscription = Stream.periodic(const Duration(milliseconds: 50))
        .listen((_) {
          try {
            final heading = ref.read(compassProvider);
            if (heading != null && heading.isFinite) {
              final now = DateTime.now();
              final alpha = _adaptiveAlpha(
                _baseHeadingAlpha,
                _lastHeadingUpdate,
                now,
              );
              _lastHeadingUpdate = now;

              _smoothedHeading = _circularEma(_smoothedHeading, heading, alpha);
              _emit();
            }
          } catch (e) {
            // Compass read failure — continue with last known heading
            debugPrint('Compass read error: $e');
          }
        });
  }

  void _startAccelerometerListening() {
    _accelSubscription?.cancel();

    if (!isMobilePlatform) {
      _smoothedPitch = 0.0;
      return;
    }

    try {
      // Use userAccelerometerEvents when available (removes gravity noise),
      // fall back to raw accelerometer.
      // Sampling at 50ms (20Hz) — safe for all devices.
      _accelSubscription =
          accelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 50),
          ).listen(
            (event) {
              _processAccelerometerEvent(event.x, event.y, event.z);
            },
            onError: (error) {
              debugPrint('Accelerometer error: $error');
              // Graceful degradation: pitch stays at last known value
            },
            cancelOnError: false,
          );
    } catch (e) {
      debugPrint('Accelerometer init error: $e');
      // Device has no accelerometer — pitch stays at 0 (arrow stays at default position)
      _smoothedPitch = 0.0;
    }
  }

  /// Process raw accelerometer data into pitch angle.
  ///
  /// Handles different device orientations robustly:
  /// - Portrait up: y ≈ -9.8, z ≈ 0 → pitch ≈ 0°
  /// - Flat face-up: y ≈ 0, z ≈ -9.8 → pitch ≈ -90°
  /// - Tilted ~45°: y ≈ -6.9, z ≈ -6.9 → pitch ≈ -45°
  void _processAccelerometerEvent(double x, double y, double z) {
    // Guard against NaN or infinity from faulty sensors
    if (!x.isFinite || !y.isFinite || !z.isFinite) return;

    // Guard against zero-magnitude (sensor returning garbage)
    final magnitude = sqrt(x * x + y * y + z * z);
    if (magnitude < 1.0) return; // Too weak — unreliable data

    // Pitch = angle of phone tilt from vertical position.
    // atan2(z, y) gives the angle between the phone's Y axis (up in portrait)
    // and the Z axis (out of screen).
    //
    // Vertical phone: y ≈ -g, z ≈ 0 → atan2(0, -g) ≈ 180° → rawPitch ≈ 0°
    // Flat phone:     y ≈ 0, z ≈ -g → atan2(-g, 0) ≈ -90° → rawPitch ≈ -90°
    final rawPitch = atan2(z, -y.abs()) * (180 / pi);

    if (!rawPitch.isFinite) return;

    final now = DateTime.now();
    final alpha = _adaptiveAlpha(_basePitchAlpha, _lastPitchUpdate, now);
    _lastPitchUpdate = now;

    _smoothedPitch = _smoothedPitch * (1 - alpha) + rawPitch * alpha;
    _smoothedPitch = _smoothedPitch.clamp(-90.0, 90.0);
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(
        DeviceOrientationData(heading: _smoothedHeading, pitch: _smoothedPitch),
      );
    }
  }

  /// Adaptive EMA alpha that adjusts based on time between sensor events.
  ///
  /// If events arrive rapidly (high Hz), use the base alpha for smooth filtering.
  /// If there's a gap (sensor hiccup), use a smaller alpha to avoid jumps.
  /// This handles devices with inconsistent sensor rates gracefully.
  double _adaptiveAlpha(double baseAlpha, DateTime? lastUpdate, DateTime now) {
    if (lastUpdate == null) return baseAlpha * 0.5; // First event, be cautious

    final elapsedMs = now.difference(lastUpdate).inMilliseconds;

    if (elapsedMs > _staleThresholdMs) {
      // Long gap — sensor was stale, apply very gentle smoothing to avoid jump
      return baseAlpha * 0.3;
    } else if (elapsedMs < 20) {
      // Very fast events — can afford more smoothing
      return baseAlpha * 0.8;
    }

    // Normal range (~30-100ms between events)
    return baseAlpha;
  }

  /// Circular exponential moving average for heading values that wrap at 360°.
  ///
  /// Properly handles the 359° → 1° wraparound.
  double _circularEma(double current, double newValue, double alpha) {
    double diff = newValue - current;
    // Normalize to [-180, 180]
    while (diff > 180) diff -= 360;
    while (diff <= -180) diff += 360;

    final result = (current + alpha * diff) % 360;
    return result.isFinite ? result : current; // Guard against NaN
  }

  /// Stop all sensor listeners and close the stream.
  void dispose() {
    _accelSubscription?.cancel();
    _compassSubscription?.cancel();
    if (!_controller.isClosed) {
      _controller.close();
    }
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
