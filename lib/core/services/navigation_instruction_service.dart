import 'dart:math';
import '../../features/admin_map/domain/entities/map_entities.dart';

/// Represents a single navigation step/instruction for the user.
class NavigationInstruction {
  /// The human-readable instruction text (e.g., "Turn left").
  final String message;
  
  /// The distance to travel for this instruction in meters.
  final double distance;
  
  /// The icon representing the action (e.g., 'straight', 'left', 'stairs_up').
  final String icon; // 'straight', 'left', 'right', 'stairs_up', 'stairs_down', 'elevator_up', 'elevator_down', 'finish'

  NavigationInstruction({
    required this.message,
    required this.distance,
    required this.icon,
  });
}

/// Service that generates user-friendly navigation instructions from a list of rooms (path).
class NavigationInstructionService {
  
  /// Generates a list of [NavigationInstruction] objects from a path.
  ///
  /// [path] is the list of [Room] objects representing the route.
  /// [corridors] is optional, used to get simplified distances.
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
    
    // 1. Initial Start
    instructions.add(NavigationInstruction(
      message: "Start at ${path.first.name}", 
      distance: 0, 
      icon: 'start'
    ));

    for (int i = 0; i < path.length - 1; i++) {
        final current = path[i];
        final next = path[i + 1];
        
        // --- Detect Floor Change (Vertical) ---
        if (_isVerticalTransition(current, next)) {
             final isUp = _isFloorUp(current, next, floorLevels);
             final isElevator = current.type == RoomType.elevator;
             
             instructions.add(NavigationInstruction(
               message: "Take ${isElevator ? 'elevator' : 'stairs'} ${isUp ? 'up' : 'down'} to next floor",
               distance: 0,
               icon: isElevator ? (isUp ? 'elevator_up' : 'elevator_down') : (isUp ? 'stairs_up' : 'stairs_down')
             ));
             continue; 
        }

        // --- Standard Horizontal Movement ---
        double segmentDist = _calculateDistance(current, next, corridors);
        
        // If it's the first segment, check orientation if available
        if (i == 0) {
           String message = "Walk straight ahead";
           String icon = "straight";
           
           if (currentHeading != null) {
               // Calculate path vector in map coordinates
               double dy = next.y - current.y;
               double dx = next.x - current.x;
               double pathAngle = atan2(dy, dx) * 180 / pi; 
               
               // Convert Math Angle (0=East, CCW) to Compass Bearing (0=North, CW)
               // Formula: Bearing = (90 - Angle) normalized
               double pathBearing = (90 - pathAngle + 360) % 360;
               
               // Adjust for Map Orientation (mapNorthOffset)
               double realWorldBearing = (pathBearing + mapNorthOffset) % 360;
               
               var turnAngle = realWorldBearing - currentHeading;
               // Normalize to -180 to 180
               while (turnAngle > 180) turnAngle -= 360;
               while (turnAngle <= -180) turnAngle += 360;
               
               final landmark = _getNextLandmarkName(path, i + 1);
               final destinationName = landmark.isNotEmpty ? landmark : next.name;

               if (turnAngle.abs() > 45) {
                   if (turnAngle.abs() > 135) {
                       // SPECIAL CASE: Turn around is a separate action
                       instructions.add(NavigationInstruction(
                           message: "Turn around",
                           distance: 0,
                           icon: "uturn"
                       ));
                       
                       message = "Walk straight towards $destinationName";
                       icon = "straight";
                       
                   } else if (turnAngle > 0) {
                       message = "Turn Right towards $destinationName"; 
                       icon = "right";
                   } else {
                        message = "Turn Left towards $destinationName";
                        icon = "left";
                   }
               }
           }
           
           instructions.add(NavigationInstruction(
             message: message,
             distance: segmentDist,
             icon: icon
           ));
        } else {
           // Calculate Angle relative to previous vector
           final previous = path[i - 1];
           
           if (_isVerticalTransition(previous, current)) {
              final isElevator = previous.type == RoomType.elevator;
              instructions.add(NavigationInstruction(
                 message: "Exit ${isElevator ? 'elevator' : 'stairs'} and walk forward",
                 distance: segmentDist,
                 icon: 'straight'
              ));
           } else {
              final turn = _getTurnDirection(previous, current, next);
              final landmark = _getNextLandmarkName(path, i + 1);
              var turnMessage = _formatTurnMessage(turn, landmark);
              
              if (turn == 'straight' && next.type == RoomType.hallway && i + 2 < path.length) {
                  final nextTurn = _getTurnDirection(current, next, path[i + 2]);
                  if (nextTurn != 'straight' && nextTurn != 'uturn') {
                      turnMessage = "Walk straight to the turn";
                  }
              }

              instructions.add(NavigationInstruction(
                message: turnMessage,
                distance: segmentDist,
                icon: turn
              ));
           }
        }
    }
    
    // Final Arrival
    instructions.add(NavigationInstruction(
      message: "Arrive at ${path.last.name}",
      distance: 0,
      icon: 'finish'
    ));
    
    return instructions;
  }

  // Look ahead for the next non-hallway room to use as a landmark
  String _getNextLandmarkName(List<Room> path, int startIndex) {
    for (int i = startIndex; i < path.length; i++) {
        final room = path[i];
        if (room.type != RoomType.hallway) {
            return room.name;
        }
    }
    // If all are hallways (unlikely) or end is hallway, return empty or last
    return "";
  }

  /// Checks if the transition between [a] and [b] is a vertical one (stairs/elevator).
  bool _isVerticalTransition(Room a, Room b) {
      if (a.connectorId != null && a.connectorId == b.connectorId && a.id != b.id) {
          return true;
      }
      return false;
  }
  
  /// Determines if moving from [a] to [b] is going up in floor level.
  bool _isFloorUp(Room a, Room b, Map<String, int> levels) {
      final levelA = levels[a.floorId] ?? 0;
      final levelB = levels[b.floorId] ?? 0;
      return levelB > levelA; 
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
  
  /// Determines the turn direction ('left', 'right', 'straight', 'uturn') based on 3 points.
  String _getTurnDirection(Room p, Room c, Room n) {
      double dx1 = c.x - p.x;
      double dy1 = c.y - p.y;
      double dx2 = n.x - c.x;
      double dy2 = n.y - c.y;
      
      double angle1 = atan2(dy1, dx1);
      double angle2 = atan2(dy2, dx2);
      double angleDiff = angle2 - angle1;
      
      while (angleDiff > pi) angleDiff -= 2 * pi;
      while (angleDiff <= -pi) angleDiff += 2 * pi;
      double degrees = angleDiff * 180 / pi;
      
      if (degrees > -45 && degrees < 45) return 'straight';
      if (degrees >= 45 && degrees < 135) return 'right';
      if (degrees <= -45 && degrees > -135) return 'left';
      return 'uturn';
  }
  
  /// Formats the turn message, optionally including a landmark.
  String _formatTurnMessage(String turnType, String landmark) {
      final suffix = landmark.isNotEmpty ? " towards $landmark" : "";
      switch (turnType) {
          case 'left': return "Turn Left$suffix";
          case 'right': return "Turn Right$suffix";
          case 'uturn': return "Make a U-Turn$suffix";
          default: return "Continue straight$suffix";
      }
  }
}
