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
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraInitializing = false; // Guard against double-init race
  bool _isPermissionDenied = false;
  String? _errorMessage;
  late AnimationController _pulseController;

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
            _errorMessage = 'Camera permission is required for AR navigation.';
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

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(navigationProvider);
    final heading =
        ref.watch(compassProvider) ?? 0.0; // Kept for ArCompassOverlay

    // Read device pitch from orientation service for ground projection
    final orientationService = ref.watch(deviceOrientationServiceProvider);
    final pitch = orientationService.currentPitch;

    // Compute AR state dynamically from instruction semantics
    final arState = computeArState(navState);

    return Scaffold(
      backgroundColor: _deepVoidBlue,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Camera preview
          _buildCameraLayer(),

          // Layer 2: Single 3D direction arrow on the ground
          if (_isCameraInitialized)
            Semantics(
              label: _arDirectionLabel(arState),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: ArDirectionPainter(
                      arState: arState,
                      pulseValue: _pulseController.value,
                      devicePitch: pitch,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),

          // Layer 3: Top bar (back button + compass)
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

                  // Mini compass — always visible when camera is running
                  if (_isCameraInitialized)
                    ArCompassOverlay(
                      currentHeading: heading,
                      targetBearing: (heading + arState.relativeBearing + 360) % 360,
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

          // Layer 5: Instruction banner (bottom)
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

  Widget _buildCameraLayer() {
    if (_errorMessage != null) return _buildErrorState(_errorMessage!);
    if (_isPermissionDenied) return _buildPermissionDeniedState();
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
