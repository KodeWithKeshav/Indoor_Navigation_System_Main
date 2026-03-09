import 'dart:math' as math;
import 'package:indoor_navigation_system/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';

/// On-track status relative to the next waypoint direction.
enum OnTrackStatus { onTrack, slightTurn, offTrack }

/// AR navigation state for the overlay rendering.
class ArNavigationState {
  /// Relative bearing for the arrow: the direction the arrow should point,
  /// derived from the current navigation instruction (not compass).
  /// -180..180 where 0 = forward, -90 = left, +90 = right, ±180 = behind.
  final double relativeBearing;
  final OnTrackStatus onTrackStatus;
  final String? nextLandmarkName;
  final double distanceToNext; // meters (from instruction)
  final bool hasData;

  const ArNavigationState({
    this.relativeBearing = 0,
    this.onTrackStatus = OnTrackStatus.offTrack,
    this.nextLandmarkName,
    this.distanceToNext = 0,
    this.hasData = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArNavigationState &&
          runtimeType == other.runtimeType &&
          relativeBearing == other.relativeBearing &&
          onTrackStatus == other.onTrackStatus &&
          nextLandmarkName == other.nextLandmarkName &&
          distanceToNext == other.distanceToNext &&
          hasData == other.hasData;

  @override
  int get hashCode => Object.hash(
    relativeBearing,
    onTrackStatus,
    nextLandmarkName,
    distanceToNext,
    hasData,
  );
}

/// Maps a navigation instruction icon to the relative bearing angle
/// that the AR arrow should point toward.
///
/// This is the core fix: instead of computing map-pixel-bearing minus
/// compass-heading (which are in different reference frames and give
/// wrong directions), we use the instruction's own semantics.
///
/// The navigation instruction service already correctly computes turn
/// directions from the path geometry. We just translate those to angles.
double instructionIconToBearing(String icon) {
  switch (icon) {
    case 'straight':
    case 'start':
    case 'enter':
    case 'exit':
    case 'finish':
    case 'stairs':
    case 'stairs_up':
    case 'stairs_down':
    case 'elevator':
    case 'elevator_up':
    case 'elevator_down':
      return 0.0; // Arrow points forward
    case 'left':
      return -90.0;
    case 'right':
      return 90.0;
    case 'sharp_left':
      return -135.0;
    case 'sharp_right':
      return 135.0;
    case 'uturn':
      return 180.0;
    default:
      return 0.0; // Default: forward
  }
}

/// Determines on-track status from the instruction's direction.
///
/// - Forward-facing instructions (straight, start, stairs, etc.) → on-track
/// - Turns (left, right) → slight turn (user needs to turn)
/// - U-turns, sharp turns → off-track (user is facing the wrong way)
OnTrackStatus instructionIconToStatus(String icon) {
  switch (icon) {
    case 'straight':
    case 'start':
    case 'enter':
    case 'exit':
    case 'stairs':
    case 'stairs_up':
    case 'stairs_down':
    case 'elevator':
    case 'elevator_up':
    case 'elevator_down':
      return OnTrackStatus.onTrack;
    case 'left':
    case 'right':
      return OnTrackStatus.slightTurn;
    case 'sharp_left':
    case 'sharp_right':
    case 'uturn':
      return OnTrackStatus.offTrack;
    case 'finish':
      return OnTrackStatus.onTrack;
    default:
      return OnTrackStatus.onTrack;
  }
}

/// Computes the AR overlay state from the current navigation state.
///
/// Uses map coordinates and phone heading to keep the arrow anchored
/// to the real world when the user rotates their phone.
/// [compassOffset] is used to calibrate any map-north misalignment.
ArNavigationState computeArState(
  NavigationState navState,
  double heading, {
  double compassOffset = 0.0,
}) {
  if (!navState.isNavigating || navState.instructions.isEmpty) {
    return const ArNavigationState(hasData: false);
  }

  if (navState.pathRooms.isEmpty) {
    return const ArNavigationState(hasData: false);
  }

  final idx = navState.currentInstructionIndex.clamp(
    0,
    navState.instructions.length - 1,
  );
  final instruction = navState.instructions[idx];

  // On the finish step, show forward arrow
  if (instruction.icon == 'finish') {
    return ArNavigationState(
      relativeBearing: 0,
      onTrackStatus: OnTrackStatus.onTrack,
      nextLandmarkName: null,
      distanceToNext: 0,
      hasData: true,
    );
  }

  // Find the exact path segment for the current room
  final roomIdx = idx.clamp(0, navState.pathRooms.length - 1);
  final nextRoomIdx = (roomIdx + 1).clamp(0, navState.pathRooms.length - 1);

  final currentRoom = navState.pathRooms[roomIdx];
  final targetRoom = navState.pathRooms[nextRoomIdx];

  // Map bearing (where 0 is up/north on the building image)
  final dx = targetRoom.x - currentRoom.x;
  final dy =
      -(targetRoom.y -
          currentRoom.y); // Negative because UI Y increases downwards

  double mapBearing = 0;
  if (dx != 0 || dy != 0) {
    mapBearing = (math.atan2(dx, dy) * 180 / math.pi + 360) % 360;
  }

  // Compute final screen bearing anchored to the physical world
  double relativeBearing = mapBearing + compassOffset - heading;
  while (relativeBearing > 180) relativeBearing -= 360;
  while (relativeBearing <= -180) relativeBearing += 360;

  // On-track status comes from the instruction semantic (not the angle)
  final status = instructionIconToStatus(instruction.icon);

  // Find next landmark (first non-hallway room ahead)
  String? landmark;
  for (int i = roomIdx + 1; i < navState.pathRooms.length; i++) {
    final room = navState.pathRooms[i];
    if (room.type != RoomType.hallway) {
      landmark = room.name;
      break;
    }
  }

  return ArNavigationState(
    relativeBearing: relativeBearing,
    onTrackStatus: status,
    nextLandmarkName: landmark,
    distanceToNext: instruction.distance,
    hasData: true,
  );
}
