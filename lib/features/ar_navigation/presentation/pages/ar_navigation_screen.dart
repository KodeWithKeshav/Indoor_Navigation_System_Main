// =============================================================================
// ar_navigation_screen.dart
//
// The main AR navigation experience. This screen composites five visual layers
// onto the device's live camera feed:
//
//   1. Camera preview (full-screen, aspect-ratio-correct)
//   2. 3D direction arrow (painted by ArDirectionPainter, anchored to ground)
//   3. Top bar with back button and live compass overlay
//   4. Map-switch button (quick escape back to 2D map view)
//   5. Instruction banner at the bottom (frosted glass, animated entry)
//
// The screen also performs camera-relative turn tracking: when the current
// instruction is a turn (left/right/u-turn), the arrow dynamically adjusts
// as the user physically rotates, converging to center when the turn is
// complete. This uses a "reference heading" captured at the moment the user
// enters a turn step.
//
// Lifecycle:
//   - Camera is initialized on mount, paused on app-inactive, resumed on
//     app-resumed. Orientation is locked to portrait for consistent AR.
//   - Handles permission denied and missing-camera edge cases gracefully.
// =============================================================================

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:indoor_navigation_system/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:indoor_navigation_system/core/services/compass_service.dart';
import '../widgets/ar_direction_painter.dart';
import '../widgets/ar_compass_overlay.dart';
import '../widgets/ar_instruction_banner.dart';
import '../providers/ar_navigation_provider.dart';
import '../../services/device_orientation_service.dart';

/// Theme constants.
const Color _deepVoidBlue = Color(0xFF0F172A);
const Color _electricGrid = Color(0xFF38BDF8);

/// The AR Navigation screen — camera preview with a single 3D arrow overlay
/// projected on the ground, plus compass, instruction banner, and controls.
class ArNavigationScreen extends ConsumerStatefulWidget {
  const ArNavigationScreen({super.key});

  @override
  ConsumerState<ArNavigationScreen> createState() => _ArNavigationScreenState();
}

class _ArNavigationScreenState extends ConsumerState<ArNavigationScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  /// Controller for the device's camera hardware.
  CameraController? _cameraController;

  /// True once the camera has been successfully initialized and is streaming.
  bool _isCameraInitialized = false;

  /// Guard flag to prevent double-initialization races (e.g. rapid lifecycle events).
  bool _isCameraInitializing = false;

  /// True when the user has denied camera permission.
  bool _isPermissionDenied = false;

  /// Non-null when a camera error occurs, displayed in the error state UI.
  String? _errorMessage;

  /// Animation controller driving the arrow's pulsing glow effect.
  late AnimationController _pulseController;

  /// The instruction index at which the current turn reference was captured.
  /// Used to detect when the user advances to a new turn step.
  int? _turnReferenceInstructionIndex;

  /// The compass heading captured when the user first arrives at a turn step.
  /// The remaining turn angle is computed as the delta from this baseline.
  double? _turnReferenceHeading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Lock to portrait for consistent AR experience
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Pulse animation for the arrow glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _cameraController?.dispose();
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
      _cameraController = null;
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  /// Requests camera permission, selects the back camera, and initializes
  /// the [CameraController] at medium resolution.
  ///
  /// Guards against double-invocation with [_isCameraInitializing].
  /// On success, locks auto-exposure and focus for a stable AR feed.
  /// On failure, sets appropriate error/permission-denied state for the UI.
  Future<void> _initializeCamera() async {
    // Prevent double-initialization race condition
    if (_isCameraInitializing) return;
    _isCameraInitializing = true;

    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _isPermissionDenied = true;
          });
        }
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _errorMessage = 'No camera found on this device.');
        }
        return;
      }

      // Pick back camera, fallback to first available
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Use medium resolution — balances overlay quality with performance.
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      // Lock auto-exposure and focus for stable AR overlay
      try {
        await _cameraController!.setExposureMode(ExposureMode.auto);
        await _cameraController!.setFocusMode(FocusMode.auto);
      } catch (_) {
        // Some devices don't support these — safe to ignore
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isPermissionDenied = false;
          _errorMessage = null;
        });
      }
    } on CameraException catch (e) {
      debugPrint('AR Camera init CameraException: ${e.code} ${e.description}');
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera error: ${e.description ?? e.code}';
        });
      }
    } catch (e) {
      debugPrint('AR Camera init error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera.';
        });
      }
    } finally {
      _isCameraInitializing = false;
    }
  }

  /// Builds the main AR view with five composited layers (see file header).
  /// Watches navigation state and compass heading reactively so the overlay
  /// updates on every frame.
  @override
  Widget build(BuildContext context) {
    // Watch the navigation state for current instruction, path progress, etc.
    final navState = ref.watch(navigationProvider);

    // Watch compass heading for the compass overlay widget
    final heading =
        ref.watch(compassProvider) ?? 0.0;

    // Watch device pitch reactively — rebuilds on every sensor update so
    // the 3D arrow tracks the phone's physical tilt in real time
    final pitch = ref
        .watch(devicePitchProvider)
        .maybeWhen(data: (value) => value, orElse: () => 0.0);

    // Compute the camera-relative AR state: for turn instructions this
    // adjusts the arrow bearing based on how far the user has physically
    // rotated since entering the turn step
    final arState = _computeCameraRelativeArState(navState, heading);

    return Scaffold(
      backgroundColor: _deepVoidBlue,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Camera preview (full-screen with aspect-ratio fill)
          _buildCameraLayer(),

          // Layer 2: 3D direction arrow painted on the "ground plane"
          // Only rendered when camera is live to avoid floating arrow on error screens
          if (_isCameraInitialized)
            Semantics(
              label: _arDirectionLabel(arState), // Accessibility description
              child: AnimatedBuilder(
                animation: _pulseController, // Rebuilds each pulse tick
                builder: (context, _) {
                  return CustomPaint(
                    painter: ArDirectionPainter(
                      arState: arState,         // Direction + on-track status
                      pulseValue: _pulseController.value, // Glow intensity
                      devicePitch: pitch,       // Phone tilt for ground anchoring
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),

          // Layer 3: Top bar — back button (left) and compass (right)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  _buildCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                    tooltip: 'Go back',
                  ),

                  // Compass overlay showing target bearing vs current heading.
                  // Converts relative bearing to absolute world bearing for display.
                  if (_isCameraInitialized)
                    ArCompassOverlay(
                      currentHeading: heading,
                      targetBearing:
                          (heading + arState.relativeBearing + 360) % 360,
                    ),
                ],
              ),
            ),
          ),

          // Layer 4: Map switch button (below compass)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 88, right: 12),
                child: _buildCircleButton(
                  icon: Icons.map_rounded,
                  onTap: () => Navigator.of(context).pop(),
                  tooltip: 'Switch to Map',
                ),
              ),
            ),
          ),

          // Layer 5: Instruction banner (bottom, animated slide-up on appear)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: const ArInstructionBanner()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.3, end: 0, duration: 400.ms),
            ),
          ),
        ],
      ),
    );
  }

  /// Converts the static instruction-based AR state into a camera-relative
  /// state for turn instructions.
  ///
  /// For non-turn instructions (straight, stairs, etc.) the base state is
  /// returned unmodified.
  ///
  /// For turns, this method:
  ///   1. Captures a "reference heading" the first time the user reaches
  ///      a turn instruction step.
  ///   2. Computes how many degrees the user has physically rotated since
  ///      that reference.
  ///   3. Returns the *remaining* turn angle as [relativeBearing], so the
  ///      arrow converges toward center (0°) as the user completes the turn.
  ///   4. Updates [onTrackStatus] dynamically:
  ///        ≤ 20° remaining → onTrack (green)
  ///        ≤ 60° remaining → slightTurn (yellow)
  ///        > 60° remaining → offTrack (red)
  ArNavigationState _computeCameraRelativeArState(
    NavigationState navState,
    double heading,
  ) {
    final baseState = computeArState(navState);
    if (!baseState.hasData || navState.instructions.isEmpty) return baseState;

    final idx = navState.currentInstructionIndex.clamp(
      0,
      navState.instructions.length - 1,
    );
    final icon = navState.instructions[idx].icon;

    if (!_isTurnIcon(icon)) {
      _turnReferenceInstructionIndex = null;
      _turnReferenceHeading = null;
      return baseState;
    }

    // Capture heading once when entering a turn step.
    if (_turnReferenceInstructionIndex != idx ||
        _turnReferenceHeading == null) {
      _turnReferenceInstructionIndex = idx;
      _turnReferenceHeading = heading;
    }

    final baseline = _turnReferenceHeading ?? heading;
    final turnedDelta = _normalizeAngle180(heading - baseline);
    final targetDelta = instructionIconToBearing(icon);
    final remaining = _normalizeAngle180(targetDelta - turnedDelta);

    final remainingAbs = remaining.abs();
    final dynamicStatus = remainingAbs <= 20
        ? OnTrackStatus.onTrack
        : (remainingAbs <= 60
              ? OnTrackStatus.slightTurn
              : OnTrackStatus.offTrack);

    return ArNavigationState(
      relativeBearing: remaining,
      onTrackStatus: dynamicStatus,
      nextLandmarkName: baseState.nextLandmarkName,
      distanceToNext: baseState.distanceToNext,
      hasData: baseState.hasData,
    );
  }

  /// Returns true if the instruction icon represents a turn that should
  /// use camera-relative heading tracking.
  bool _isTurnIcon(String icon) {
    return icon == 'left' ||
        icon == 'right' ||
        icon == 'sharp_left' ||
        icon == 'sharp_right' ||
        icon == 'uturn';
  }

  /// Normalizes an angle to the range (-180, +180] for shortest-path delta calculations.
  double _normalizeAngle180(double angle) {
    var normalized = angle;
    while (normalized > 180) normalized -= 360;
    while (normalized <= -180) normalized += 360;
    return normalized;
  }

  /// Accessibility label describing the current AR arrow direction.
  String _arDirectionLabel(ArNavigationState arState) {
    if (!arState.hasData) return 'AR navigation arrow';
    final status = switch (arState.onTrackStatus) {
      OnTrackStatus.onTrack => 'On track',
      OnTrackStatus.slightTurn => 'Turn ahead',
      OnTrackStatus.offTrack => 'Off track, turn around',
    };
    final distance = arState.distanceToNext > 0
        ? ', ${arState.distanceToNext.toStringAsFixed(0)} meters'
        : '';
    final landmark = arState.nextLandmarkName != null
        ? ', toward ${arState.nextLandmarkName}'
        : '';
    return '$status$distance$landmark';
  }

  /// Builds the camera preview layer, handling three error states:
  ///   - Permission denied → settings prompt
  ///   - Camera error → error message with return-to-map button
  ///   - Not yet initialized → loading spinner
  ///
  /// When initialized, the preview is scaled to fill the screen (cover mode)
  /// regardless of the camera's native aspect ratio.
  Widget _buildCameraLayer() {
    if (_isPermissionDenied) return _buildPermissionDeniedState();
    if (_errorMessage != null) return _buildErrorState(_errorMessage!);
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: _electricGrid),
      );
    }

    final previewSize = _cameraController!.value.previewSize;
    if (previewSize == null) {
      return const Center(
        child: CircularProgressIndicator(color: _electricGrid),
      );
    }

    final cameraAspect = previewSize.height / previewSize.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenAspect = constraints.maxWidth / constraints.maxHeight;
        final double scale;
        if (screenAspect > cameraAspect) {
          scale = constraints.maxWidth / (constraints.maxHeight * cameraAspect);
        } else {
          scale = (constraints.maxHeight * cameraAspect) / constraints.maxWidth;
        }

        return ClipRect(
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Center(
              child: AspectRatio(
                aspectRatio: cameraAspect,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the "Camera Permission Required" state with a button
  /// that opens the system app settings for the user to grant access.
  Widget _buildPermissionDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              color: _electricGrid.withValues(alpha: 0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Grant camera access to use AR navigation.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _electricGrid,
                foregroundColor: _deepVoidBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Return to Map',
                style: TextStyle(color: _electricGrid.withValues(alpha: 0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a generic error state displaying [message] with a
  /// "Return to Map" button to navigate back.
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Return to Map',
                style: TextStyle(color: _electricGrid),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a circular semi-transparent button used for the back and
  /// map-switch controls in the AR overlay.
  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _deepVoidBlue.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: _electricGrid.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );

    if (tooltip != null) return Tooltip(message: tooltip, child: button);
    return button;
  }
}
