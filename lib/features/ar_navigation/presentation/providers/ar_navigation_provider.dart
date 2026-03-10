import 'package:indoor_navigation_system/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';

/// Instruction category — indicates what the current step asks of the user.
/// Note: this reflects the instruction type, not live compass deviation.
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

/// Determines instruction category from the icon.
///
/// - Forward-facing instructions (straight, start, stairs, etc.) → onTrack
/// - Turns (left, right) → slightTurn (user will need to turn)
/// - U-turns, sharp turns → offTrack (large direction change needed)
///
/// This is NOT live compass-based deviation detection.
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
/// This is a pure function — no compass, no map coordinates.
/// The arrow direction comes entirely from what the instruction says.
ArNavigationState computeArState(NavigationState navState) {
  if (!navState.isNavigating || navState.instructions.isEmpty) {
    return const ArNavigationState(hasData: false);
  }

  final idx = navState.currentInstructionIndex.clamp(
    0,
    navState.instructions.length - 1,
  );
  final instruction = navState.instructions[idx];

  final bearing = instructionIconToBearing(instruction.icon);
  final status = instructionIconToStatus(instruction.icon);

  // Find next landmark (first non-hallway room ahead of this instruction's
  // room position). Uses roomIndex so the lookup is accurate even when
  // instruction count differs from path room count.
  String? landmark;
  if (instruction.icon != 'finish' && navState.pathRooms.isNotEmpty) {
    final searchStart = (instruction.roomIndex + 1).clamp(
      0,
      navState.pathRooms.length - 1,
    );
    for (int i = searchStart; i < navState.pathRooms.length; i++) {
      if (navState.pathRooms[i].type != RoomType.hallway) {
        landmark = navState.pathRooms[i].name;
        break;
      }
    }
  }

  return ArNavigationState(
    relativeBearing: bearing,
    onTrackStatus: status,
    nextLandmarkName: landmark,
    distanceToNext: instruction.distance,
    hasData: true,
  );
}
