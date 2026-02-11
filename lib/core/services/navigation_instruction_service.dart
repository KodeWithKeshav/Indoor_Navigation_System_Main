import 'dart:math';
import '../../features/admin_map/domain/entities/map_entities.dart';

/// Represents a single navigation step/instruction for the user.
class NavigationInstruction {
  /// The human-readable instruction text (e.g., "Turn left").
  final String message;
  
  /// The distance to travel for this instruction in meters.
  final double distance;
  
  /// The icon representing the action (e.g., 'straight', 'left', 'stairs_up').
  final String icon; // 'straight', 'left', 'right', 'stairs_up', 'stairs_down', 'elevator_up', 'elevator_down', 'finish', 'start', 'enter', 'exit'

  NavigationInstruction({
    required this.message,
    required this.distance,
    required this.icon,
  });
}

/// Service that generates user-friendly navigation instructions from a list of rooms (path).
///
/// Design principles:
/// - Each turn is its own step (distance = 0).
/// - Each walk is its own step (with the admin-defined corridor distance).
/// - Enter/Exit building are dedicated steps.
/// - Distances come from corridor data (admin-defined), never combined across turns.
class NavigationInstructionService {
  
  /// Generates a list of [NavigationInstruction] objects from a path.
  ///
  /// [path] is the list of [Room] objects representing the route.
  /// [corridors] is optional, used to get admin-defined distances.
  /// [floorLevels] map of floor IDs to their integer levels, used for up/down determination.
  /// [currentHeading] optional user compass heading to provide relative initial direction.
  /// [mapNorthOffset] optional offset if the map isn't aligned to true north.
  List<NavigationInstruction> generateInstructions(
    List<Room> path, {
    List<Corridor>? corridors,
    Map<String, int> floorLevels = const {},
    double? currentHeading,
    double mapNorthOffset = 0.0,
  }) {
    if (path.isEmpty) return [];
    if (path.length == 1) return [
        NavigationInstruction(message: "You are at your destination", distance: 0, icon: 'finish')
    ];

    final instructions = <NavigationInstruction>[];
    
    // 1. Start instruction
    instructions.add(NavigationInstruction(
      message: "Start at ${path.first.name}", 
      distance: 0, 
      icon: 'start'
    ));

    for (int i = 0; i < path.length - 1; i++) {
        final current = path[i];
        final next = path[i + 1];
        
        // --- Detect Floor Change (Vertical Transition) ---
        if (_isVerticalTransition(current, next, floorLevels)) {
             final isUp = _isFloorUp(current, next, floorLevels);
             final isElevator = current.type == RoomType.elevator;
             
             instructions.add(NavigationInstruction(
               message: "Take ${isElevator ? 'elevator' : 'stairs'} ${isUp ? 'up' : 'down'} to next floor",
               distance: 0,
               icon: isElevator ? (isUp ? 'elevator_up' : 'elevator_down') : (isUp ? 'stairs_up' : 'stairs_down')
             ));
             continue; 
        }

        // --- Detect Enter/Exit Building ---
        if (_isBuildingTransition(current, next)) {
             // Determine direction: entering or exiting
             final isExiting = current.type == RoomType.entrance && _isOutdoorNode(next);
             final isEntering = current.type == RoomType.entrance && !_isOutdoorNode(next) && _isOutdoorNode(current) == false;
             
             // More robust: check if we're going from indoor to outdoor or vice versa
             final currentOutdoor = _isOutdoorNode(current);
             final nextOutdoor = _isOutdoorNode(next);
             
             if (currentOutdoor && !nextOutdoor) {
                 // Outdoor → Indoor = Enter building
                 instructions.add(NavigationInstruction(
                   message: "Enter building",
                   distance: 0,
                   icon: 'enter'
                 ));
             } else if (!currentOutdoor && nextOutdoor) {
                 // Indoor → Outdoor = Exit building
                 instructions.add(NavigationInstruction(
                   message: "Exit building",
                   distance: 0,
                   icon: 'exit'
                 ));
             } else if (next.type == RoomType.entrance || current.type == RoomType.entrance) {
                 // Entrance node transition between floors/buildings
                 instructions.add(NavigationInstruction(
                   message: "Pass through entrance",
                   distance: 0,
                   icon: 'enter'
                 ));
             }
             
             // Add walk distance if significant
             double segmentDist = _calculateDistance(current, next, corridors);
             if (segmentDist > 2) {
                 instructions.add(NavigationInstruction(
                   message: "Walk straight",
                   distance: segmentDist,
                   icon: 'straight'
                 ));
             }
             continue;
        }

        // --- Standard Horizontal Movement ---
        double segmentDist = _calculateDistance(current, next, corridors);
        
        if (i == 0) {
           // First segment: check orientation if compass heading is available
           _addFirstSegmentInstructions(
             instructions, path, i, segmentDist,
             currentHeading: currentHeading,
             mapNorthOffset: mapNorthOffset,
           );
        } else {
           final previous = path[i - 1];
           
           // After a vertical transition, just walk forward
           if (_isVerticalTransition(previous, current, floorLevels)) {
              final isElevator = previous.type == RoomType.elevator;
              instructions.add(NavigationInstruction(
                 message: "Exit ${isElevator ? 'elevator' : 'stairs'} and walk forward",
                 distance: segmentDist,
                 icon: 'straight'
              ));
           } else {
              // Calculate turn direction from previous→current→next
              final turn = _getTurnDirection(previous, current, next);
              
              if (turn != 'straight') {
                // Emit turn instruction (zero distance)
                final landmark = _getNextLandmarkName(path, i + 1);
                final turnMessage = _formatTurnMessage(turn, landmark);
                instructions.add(NavigationInstruction(
                  message: turnMessage,
                  distance: 0,
                  icon: turn
                ));
              }
              
              // Emit walk instruction with admin-defined distance
              if (segmentDist > 2) { // Threshold 2m to filter noise
                instructions.add(NavigationInstruction(
                  message: "Walk straight",
                  distance: segmentDist,
                  icon: 'straight'
                ));
              }
           }
        }
    }
    
    // Final Arrival
    instructions.add(NavigationInstruction(
      message: "Arrive at ${path.last.name}",
      distance: 0,
      icon: 'finish'
    ));
    
    return _simplifyInstructions(instructions);
  }

  /// Handles the first segment of the path, which may use compass orientation.
  void _addFirstSegmentInstructions(
    List<NavigationInstruction> instructions,
    List<Room> path,
    int i,
    double segmentDist, {
    double? currentHeading,
    double mapNorthOffset = 0.0,
  }) {
    final current = path[i];
    final next = path[i + 1];

    if (currentHeading != null) {
        // Calculate path vector in map coordinates
        double dy = next.y - current.y;
        double dx = next.x - current.x;
        double pathAngle = atan2(dy, dx) * 180 / pi; 
        
        // Convert Math Angle (0=East, CCW) to Compass Bearing (0=North, CW)
        double pathBearing = (90 - pathAngle + 360) % 360;
        
        // Adjust for Map Orientation
        double realWorldBearing = (pathBearing + mapNorthOffset) % 360;
        
        var turnAngle = realWorldBearing - currentHeading;
        // Normalize to -180 to 180
        while (turnAngle > 180) { turnAngle -= 360; }
        while (turnAngle <= -180) { turnAngle += 360; }
        
        final landmark = _getNextLandmarkName(path, i + 1);
        final destinationName = landmark.isNotEmpty ? landmark : next.name;

        if (turnAngle.abs() > 45) {
            if (turnAngle.abs() > 135) {
                // Turn around
                instructions.add(NavigationInstruction(
                    message: "Turn around",
                    distance: 0,
                    icon: "uturn"
                ));
            } else if (turnAngle > 0) {
                instructions.add(NavigationInstruction(
                    message: "Turn Right towards $destinationName",
                    distance: 0,
                    icon: "right"
                ));
            } else {
                instructions.add(NavigationInstruction(
                    message: "Turn Left towards $destinationName",
                    distance: 0,
                    icon: "left"
                ));
            }
        }
    }
    
    // Always add the walk step with actual distance
    if (segmentDist > 2) {
      instructions.add(NavigationInstruction(
        message: "Walk straight",
        distance: segmentDist,
        icon: 'straight'
      ));
    }
  }

  /// Minimal simplification: only merge consecutive straight-walk steps 
  /// (user walking in a straight line through waypoints).
  /// Does NOT merge turns with walks. Does NOT combine distances across turns.
  List<NavigationInstruction> _simplifyInstructions(List<NavigationInstruction> raw) {
      if (raw.isEmpty) return [];
      
      final simplified = <NavigationInstruction>[];
      var current = raw.first;
      
      for (int i = 1; i < raw.length; i++) {
          final next = raw[i];
          
          // Only merge: consecutive straight walks (same icon = 'straight', both have distance > 0)
          // This collapses hallway waypoints into a single "Walk straight — 50m"
          final isBothStraightWalk = current.icon == 'straight' && next.icon == 'straight'
              && current.distance > 0 && next.distance > 0;
          
          if (isBothStraightWalk) {
              current = NavigationInstruction(
                  message: current.message, 
                  distance: current.distance + next.distance,
                  icon: current.icon
              );
              continue;
          }
          
          simplified.add(current);
          current = next;
      }
      simplified.add(current);
      
      return simplified;
  }

  /// Determines the turn direction based on 3 consecutive points.
  /// Uses a 60° threshold to filter slight corridor bends.
  String _getTurnDirection(Room p, Room c, Room n) {
      double dx1 = c.x - p.x;
      double dy1 = c.y - p.y;
      double dx2 = n.x - c.x;
      double dy2 = n.y - c.y;
      
      double angle1 = atan2(dy1, dx1);
      double angle2 = atan2(dy2, dx2);
      double angleDiff = angle2 - angle1;
      
      while (angleDiff > pi) { angleDiff -= 2 * pi; }
      while (angleDiff <= -pi) { angleDiff += 2 * pi; }
      double degrees = angleDiff * 180 / pi;
      
      // 60° threshold — filters subtle bends in corridors
      if (degrees > -60 && degrees < 60) return 'straight';
      if (degrees >= 60 && degrees < 150) return 'right';
      if (degrees <= -60 && degrees > -150) return 'left';
      if (degrees >= 150) return 'sharp_right';
      if (degrees <= -150) return 'sharp_left';
      return 'straight'; // Fallback
  }

  /// Look ahead for the next non-hallway room to use as a landmark.
  String _getNextLandmarkName(List<Room> path, int startIndex) {
    for (int i = startIndex; i < path.length; i++) {
        final room = path[i];
        if (room.type != RoomType.hallway) {
            return room.name;
        }
    }
    return "";
  }

  /// Checks if two rooms represent a vertical transition (stairs/elevator).
  bool _isVerticalTransition(Room a, Room b, Map<String, int> levels) {
      if (a.connectorId != null && a.connectorId == b.connectorId && a.id != b.id) {
          // If we have level data, check actual level
          if (levels.containsKey(a.floorId) && levels.containsKey(b.floorId)) {
             return levels[a.floorId] != levels[b.floorId];
          }
          // Fallback: Check floor ID string difference
          return a.floorId.toLowerCase() != b.floorId.toLowerCase();
      }
      return false;
  }
  
  /// Determines if moving from [a] to [b] is going up in floor level.
  bool _isFloorUp(Room a, Room b, Map<String, int> levels) {
      final levelA = levels[a.floorId] ?? 0;
      final levelB = levels[b.floorId] ?? 0;
      return levelB > levelA; 
  }

  /// Checks whether a node is an "outdoor" node (campus/ground level).
  bool _isOutdoorNode(Room room) {
    return room.type == RoomType.ground ||
           room.type == RoomType.parking ||
           room.floorId.toLowerCase().contains('campus') ||
           room.floorId.toLowerCase() == 'ground';
  }

  /// Detects a building boundary transition (enter/exit).
  /// True if the two rooms are on different floors AND at least one is an entrance node.
  bool _isBuildingTransition(Room current, Room next) {
    if (current.floorId == next.floorId) return false;
    return current.type == RoomType.entrance || next.type == RoomType.entrance;
  }

  /// Calculates the distance between two rooms, preferring corridor data if available.
  double _calculateDistance(Room a, Room b, List<Corridor>? corridors) {
    if (corridors != null) {
      try {
        final edge = corridors.firstWhere((c) => 
          (c.startRoomId == a.id && c.endRoomId == b.id) || 
          (c.startRoomId == b.id && c.endRoomId == a.id)
        );
        return edge.distance;
      } catch (_) {}
    }
    return sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2));
  }
  
  /// Formats the turn message, optionally including a landmark.
  String _formatTurnMessage(String turnType, String landmark) {
      final suffix = landmark.isNotEmpty ? " towards $landmark" : "";
      switch (turnType) {
          case 'left': return "Turn Left$suffix";
          case 'right': return "Turn Right$suffix";
          case 'sharp_left': return "Sharp Left Turn$suffix";
          case 'sharp_right': return "Sharp Right Turn$suffix";
          case 'uturn': return "Turn Around$suffix";
          default: return "Continue straight$suffix";
      }
  }
}
