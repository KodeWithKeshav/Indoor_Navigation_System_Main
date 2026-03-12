// =============================================================================
// ar_navigation_provider.dart
//
// Pure-function state computation for the AR navigation overlay. This file
// translates navigation instructions into arrow direction, color, and
// contextual data without any dependency on compass heading or map
// coordinates.
//
// Architecture rationale:
//   The navigation instruction service already computes correct turn
//   directions from path geometry (left, right, straight, etc.). Rather
//   than re-deriving bearing from map-pixel coordinates minus compass
//   heading (which mixes incompatible reference frames), we map
//   instruction icons directly to arrow angles. This is simpler, more
//   reliable, and works identically on all devices regardless of compass
//   accuracy.
//
// Consumed by:
//   - ArDirectionPainter (arrow bearing + color)
//   - ArInstructionBanner (on-track status + next landmark)
//   - ArNavigationScreen (camera-relative turn adjustment)
// =============================================================================

import 'package:indoor_navigation_system/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';

/// Instruction category — indicates what the current step asks of the user.
///
/// Important: this reflects the *instruction type* (semantic), NOT live
/// compass-based deviation detection. A "left" turn instruction always
/// produces [slightTurn], regardless of which way the user is actually facing.
enum OnTrackStatus { onTrack, slightTurn, offTrack }

/// Immutable snapshot of the AR overlay state for a single render frame.
///
/// This is the single source of truth consumed by [ArDirectionPainter],
/// [ArCompassOverlay], and [ArInstructionBanner] to render the AR UI.
class ArNavigationState {
  /// Relative bearing for the 3D arrow: the direction the arrow should point,
  /// derived from the current navigation instruction (not compass).
  /// Range: -180..+180 where 0 = forward, -90 = left, +90 = right, ±180 = behind.
  final double relativeBearing;

  /// The instruction-based on-track category (see [OnTrackStatus] docs).
  final OnTrackStatus onTrackStatus;

  /// Name of the next non-hallway room ahead on the path, if any.
  /// Displayed in the instruction banner as "-> Room Name".
  final String? nextLandmarkName;

  /// Distance in meters to the next waypoint, from the current instruction.
  final double distanceToNext;

  /// False when navigation is inactive or there are no instructions.
  /// Painters check this before rendering.
  final bool hasData;

  const ArNavigationState({
    this.relativeBearing = 0,
    this.onTrackStatus = OnTrackStatus.offTrack,
    this.nextLandmarkName,
    this.distanceToNext = 0,
    this.hasData = false,
  });

  /// Value equality — used by ArDirectionPainter.shouldRepaint to skip
  /// unnecessary repaints when the state hasn't actually changed.
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

/// Maps a navigation instruction icon string to the relative bearing angle
/// (in degrees) that the AR arrow should point toward.
///
/// Angle convention:
///   -  0°  = straight ahead (forward)
///   - -90° = left
///   - +90° = right
///   - ±180° = u-turn (behind)
///
/// Forward-ish instructions (stairs, elevator, start, finish, etc.) all
/// map to 0° because the user should continue in their current direction.
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

/// Determines the on-track status category from an instruction icon.
///
/// Categories:
///   - [OnTrackStatus.onTrack]:    Forward movement (straight, start, stairs, etc.)
///   - [OnTrackStatus.slightTurn]: Normal turns (left, right)
///   - [OnTrackStatus.offTrack]:   Major direction changes (sharp turns, u-turns)
///
/// This drives both the arrow color and the instruction banner's status strip.
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

/// Computes the complete AR overlay state from the current navigation state.
///
/// This is a **pure function** — no compass, no map coordinates, no side effects.
/// The arrow direction comes entirely from the instruction icon semantics.
///
/// Also performs a forward-scan through [navState.pathRooms] to find the next
/// non-hallway room name (used as the upcoming landmark in the instruction banner).
ArNavigationState computeArState(NavigationState navState) {
  if (!navState.isNavigating || navState.instructions.isEmpty) {
    return const ArNavigationState(hasData: false);
  }

  // Resolve the current instruction (clamped to valid range)
  final idx = navState.currentInstructionIndex.clamp(
    0,
    navState.instructions.length - 1,
  );
  final instruction = navState.instructions[idx];

  // Map the instruction icon to an arrow bearing and status category
  final bearing = instructionIconToBearing(instruction.icon);
  final status = instructionIconToStatus(instruction.icon);

  // Forward-scan path rooms to find the next non-hallway room (landmark).
  // Uses the instruction's roomIndex for accurate position lookup, since
  // instruction count may differ from path room count due to merged steps.
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
