import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:indoor_navigation_system/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/core/services/compass_service.dart';
import '../widgets/ar_direction_painter.dart';
import '../widgets/ar_compass_overlay.dart';
import '../widgets/ar_instruction_banner.dart';
import '../providers/ar_navigation_provider.dart';

/// Theme constants.
const Color _deepVoidBlue = Color(0xFF0F172A);
const Color _electricGrid = Color(0xFF38BDF8);

/// The AR Navigation screen — camera preview with pseudo-3D arrow overlay.
class ArNavigationScreen extends ConsumerStatefulWidget {
  const ArNavigationScreen({super.key});

  @override
  ConsumerState<ArNavigationScreen> createState() => _ArNavigationScreenState();
}

class _ArNavigationScreenState extends ConsumerState<ArNavigationScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;
  String? _errorMessage;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Lock to portrait for consistent AR experience
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Pulse animation for the lead arrow
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
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      _cameraController = null;
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
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

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isPermissionDenied = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('AR Camera init error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: ${e.toString()}';
        });
      }
    }
  }

  /// Compute the AR overlay state directly from compass + navigation state.
  /// No intermediate providers — straight data flow.
  ArNavigationState _computeArState(NavigationState navState, double heading) {
    if (!navState.isNavigating || navState.pathRooms.isEmpty) {
      return const ArNavigationState(hasData: false);
    }

    final pathRooms = navState.pathRooms;
    final currentIdx = navState.currentInstructionIndex.clamp(
      0,
      pathRooms.length - 1,
    );
    final targetIdx = (navState.currentInstructionIndex + 1).clamp(
      0,
      pathRooms.length - 1,
    );

    final currentRoom = pathRooms[currentIdx];
    final targetRoom = pathRooms[targetIdx];

    // Bearing from current room to target in map coordinates (0 = map-up)
    final dx = targetRoom.x - currentRoom.x;
    final dy = -(targetRoom.y - currentRoom.y); // Screen Y is inverted
    final mapBearing = (math.atan2(dx, dy) * 180 / math.pi + 360) % 360;

    // Relative bearing = where waypoint is relative to where phone is pointing
    double relative = mapBearing - heading;
    while (relative > 180) {
      relative -= 360;
    }
    while (relative <= -180) {
      relative += 360;
    }

    // On-track status
    final absRel = relative.abs();
    OnTrackStatus status;
    if (absRel < 20) {
      status = OnTrackStatus.onTrack;
    } else if (absRel < 60) {
      status = OnTrackStatus.slightTurn;
    } else {
      status = OnTrackStatus.offTrack;
    }

    // Distance (euclidean map units)
    final dist = math.sqrt(
      (dx * dx) +
          (currentRoom.y - targetRoom.y) * (currentRoom.y - targetRoom.y),
    );

    // Next landmark (first non-hallway room ahead)
    String? landmark;
    for (int i = targetIdx; i < pathRooms.length; i++) {
      final room = pathRooms[i];
      if (room.type != RoomType.hallway) {
        landmark = room.name;
        break;
      }
    }

    final remaining = pathRooms.length - currentIdx;

    return ArNavigationState(
      relativeBearing: relative,
      onTrackStatus: status,
      nextLandmarkName: landmark,
      distanceToNext: dist,
      trailCount: remaining.clamp(2, 5),
      hasData: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(navigationProvider);
    final heading = ref.watch(compassProvider) ?? 0.0;

    // Compute AR state directly — no broken provider chain
    final arState = _computeArState(navState, heading);

    return Scaffold(
      backgroundColor: _deepVoidBlue,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Camera preview
          _buildCameraLayer(),

          // Layer 2: Direction arrow overlay
          if (_isCameraInitialized)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  painter: ArDirectionPainter(
                    arState: arState,
                    pulseValue: _pulseController.value,
                  ),
                  size: Size.infinite,
                );
              },
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
                  ),

                  // Mini compass — always visible when camera is running
                  if (_isCameraInitialized)
                    ArCompassOverlay(
                      currentHeading: heading,
                      targetBearing: _computeTargetBearing(navState),
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

  double _computeTargetBearing(NavigationState navState) {
    if (navState.pathRooms.length <= 1) return 0;
    final idx = navState.currentInstructionIndex.clamp(
      0,
      navState.pathRooms.length - 1,
    );
    final nextIdx = (idx + 1).clamp(0, navState.pathRooms.length - 1);
    final current = navState.pathRooms[idx];
    final target = navState.pathRooms[nextIdx];
    final dx = target.x - current.x;
    final dy = -(target.y - current.y);
    return (math.atan2(dx, dy) * 180 / math.pi + 360) % 360;
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
        double scale;
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
