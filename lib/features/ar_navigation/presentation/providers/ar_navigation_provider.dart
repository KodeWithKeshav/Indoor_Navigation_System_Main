import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indoor_navigation_system/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/ar_navigation/services/device_orientation_service.dart';

/// On-track status relative to the next waypoint direction.
enum OnTrackStatus { onTrack, slightTurn, offTrack }

/// AR navigation state for the overlay rendering.
class ArNavigationState {
  final double relativeBearing; // -180..180 relative to device heading
  final OnTrackStatus onTrackStatus;
  final String? nextLandmarkName;
  final double distanceToNext; // meters (euclidean in map units)
  final int trailCount; // number of trail chevrons to draw
  final bool hasData;

  const ArNavigationState({
    this.relativeBearing = 0,
    this.onTrackStatus = OnTrackStatus.offTrack,
    this.nextLandmarkName,
    this.distanceToNext = 0,
    this.trailCount = 4,
    this.hasData = false,
  });
}

/// Provider that computes AR overlay data from existing navigation state
/// and fused device orientation.
///
/// Uses `ref.listen` (not `ref.watch`) for navigation state changes
/// so that `build()` does NOT reset the state each time the step advances.
class ArNavigationNotifier extends Notifier<ArNavigationState> {
  StreamSubscription? _orientationSubscription;
  double _lastHeading = 0;
  double _lastPitch = 0;

  @override
  ArNavigationState build() {
    ref.onDispose(() {
      _orientationSubscription?.cancel();
    });

    // Listen (NOT watch) to navigation state so step changes trigger
    // a recompute without resetting state.
    ref.listen(navigationProvider, (_, __) {
      _recompute(_lastHeading, _lastPitch);
    });

    // Start listening to orientation sensor stream
    _startListening();

    // Return initial state — will be replaced on first sensor event
    return const ArNavigationState();
  }

  void _startListening() {
    final orientationService = ref.read(deviceOrientationServiceProvider);

    _orientationSubscription?.cancel();
    _orientationSubscription = orientationService.orientationStream.listen((
      data,
    ) {
      _lastHeading = data.heading;
      _lastPitch = data.pitch;
      _recompute(data.heading, data.pitch);
    });
  }

  void _recompute(double deviceHeading, double pitch) {
    final navState = ref.read(navigationProvider);
    if (!navState.isNavigating || navState.pathRooms.isEmpty) {
      if (state.hasData) {
        state = const ArNavigationState(hasData: false);
      }
      return;
    }

    final currentIndex = navState.currentInstructionIndex;
    final pathRooms = navState.pathRooms;

    // Current room (where user is) and target room (where user is heading)
    final currentRoomIdx = currentIndex.clamp(0, pathRooms.length - 1);
    final targetRoomIdx = (currentIndex + 1).clamp(0, pathRooms.length - 1);

    final currentRoom = pathRooms[currentRoomIdx];
    final targetRoom = pathRooms[targetRoomIdx];

    // Bearing from current room to target room in map coordinates
    final mapBearing = _bearingBetween(currentRoom, targetRoom);

    // Relative bearing = map bearing - device heading (normalized to -180..180)
    double relative = mapBearing - deviceHeading;
    while (relative > 180) {
      relative -= 360;
    }
    while (relative <= -180) {
      relative += 360;
    }

    // On-track status
    final absRelative = relative.abs();
    OnTrackStatus status;
    if (absRelative < 20) {
      status = OnTrackStatus.onTrack;
    } else if (absRelative < 60) {
      status = OnTrackStatus.slightTurn;
    } else {
      status = OnTrackStatus.offTrack;
    }

    // Distance to next waypoint
    final dist = _euclideanDist(currentRoom, targetRoom);

    // Next landmark name — find the first non-hallway room ahead
    String? landmark;
    for (int i = targetRoomIdx; i < pathRooms.length; i++) {
      if (pathRooms[i].type != RoomType.hallway) {
        landmark = pathRooms[i].name;
        break;
      }
    }

    // Trail count based on remaining path
    final remaining = pathRooms.length - currentRoomIdx;
    final trailCount = remaining.clamp(2, 5);

    state = ArNavigationState(
      relativeBearing: relative,
      onTrackStatus: status,
      nextLandmarkName: landmark,
      distanceToNext: dist,
      trailCount: trailCount,
      hasData: true,
    );
  }

  /// Calculate bearing from room A to room B using map pixel coordinates.
  /// Returns degrees 0..360 (0 = map-up).
  double _bearingBetween(Room a, Room b) {
    final dx = b.x - a.x;
    final dy = -(b.y - a.y); // Negate Y because screen Y is inverted
    final angle = atan2(dx, dy) * (180 / pi);
    return (angle + 360) % 360;
  }

  /// Euclidean distance between two rooms (in map units, treated as meters).
  double _euclideanDist(Room a, Room b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    return sqrt(dx * dx + dy * dy);
  }
}

final arNavigationProvider =
    NotifierProvider<ArNavigationNotifier, ArNavigationState>(
      ArNavigationNotifier.new,
    );
