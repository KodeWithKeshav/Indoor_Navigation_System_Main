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

        // --- Detect Map Transition (Enter/Exit Building) ---
        // If floors change but levels are same (vertical check passed as false), it's a map boundary.
        if (current.floorId != next.floorId) {
             String action = "Walk to";
             // Assume 'ground' or 'campus' is the outdoor map
             final isNextOutside = next.floorId.toLowerCase() == 'ground' || next.floorId.toLowerCase().contains('campus');
             final isCurrentOutside = current.floorId.toLowerCase() == 'ground' || current.floorId.toLowerCase().contains('campus');
             
             if (isNextOutside && !isCurrentOutside) {
                 action = "Exit building";
             } else if (isCurrentOutside && !isNextOutside) {
                 action = "Enter building";
             }
             
             // Calculate turn for Icon, but keep text simple
             String turnDirection = "straight";
             
             if (i > 0) {
                 final previous = path[i - 1];
                 turnDirection = _getTurnDirection(previous, current, next);
             }

             // Force straight icon for Enter/Exit to avoid "Left then Left" confusion
             // unless it's a complete reversal
             if (turnDirection != 'uturn' && turnDirection != 'sharp_left' && turnDirection != 'sharp_right') {
                 turnDirection = 'straight';
             }

             double segmentDist = _calculateDistance(current, next, corridors);
             
              instructions.add(NavigationInstruction(
                 message: action, 
                 distance: 0, // Split instruction: Action first
                 icon: turnDirection 
             ));
             
             if (segmentDist > 5) { // Threshold 5m to avoid noise
                 instructions.add(NavigationInstruction(
                   message: "Continue straight",
                   distance: segmentDist,
                   icon: 'straight'
                 ));
             }
             continue;
        }

        // --- Standard Horizontal Movement ---
        double segmentDist = _calculateDistance(current, next, corridors);
        
        // If it's the first segment, check orientation if available
        if (i == 0) {
           String message = "Go straight"; // simplified to avoid "Walk straight ahead and walk 20m"
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
           
           // Split first instruction if long
           if (icon != 'straight') {
                instructions.add(NavigationInstruction(
                    message: message,
                    distance: 0,
                    icon: icon
                ));
                if (segmentDist > 5) {
                    instructions.add(NavigationInstruction(
                        message: "Continue straight",
                        distance: segmentDist,
                        icon: 'straight'
                    ));
                }
           } else {
               instructions.add(NavigationInstruction(
                 message: message,
                 distance: segmentDist,
                 icon: icon
               ));
           }
        } else {
           // Calculate Angle relative to previous vector
           final previous = path[i - 1];
           
           if (_isVerticalTransition(previous, current, floorLevels)) {
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

              // Allow Turn to carry distance (Merged View)
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
    
    return _simplifyInstructions(instructions);
  }

  /// Merges consecutive instructions to reduce noise (e.g., Turn Right + Walk Straight -> Turn Right with combined distance).
  /// Merges consecutive instructions to reduce noise (e.g., Turn Right + Walk Straight -> Turn Right with combined distance).
  List<NavigationInstruction> _simplifyInstructions(List<NavigationInstruction> raw) {
      if (raw.isEmpty) return [];
      
      final simplified = <NavigationInstruction>[];
      var current = raw.first;
      
      for (int i = 1; i < raw.length; i++) {
          final next = raw[i];
          
          final isCurrentStraight = current.icon == 'straight';
          final isNextStraight = next.icon == 'straight';
          final isSameAction = current.message == next.message && current.icon == next.icon;
          
          // Do NOT merge if current is 'start'
          final isStart = current.icon == 'start';

           // MERGE LOGIC:
           // 1. Merge consecutive "Walk Straight" instructions 
           // 2. Merge Turn + Walk (e.g., Turn Left (segmentDist) + Walk Straight (nextDist) -> Turn Left (total))
           //    This ensures the 'Turn' row shows the full distance of that leg in the badge.
           
           bool shouldMerge = false;
           
           // Case 1: Straight + Straight
           if (isCurrentStraight && isNextStraight && !isStart) {
               shouldMerge = true;
           }
           // Case 2: Turn + Straight (Standard Leg)
           else if (!isCurrentStraight && isNextStraight && !isStart) {
               shouldMerge = true; 
           }
           // Case 3: Same Action (Turn + Turn)
           // Only merge if distance is reasonable (< 40m squash)
           // This handles typical "Zig-Zag" corridors or short segments.
           else if (isSameAction && current.distance < 40) {
               shouldMerge = true;
           }

           if (shouldMerge) {
               final totalDist = current.distance + next.distance;
               
               // Combine distances
               current = NavigationInstruction(
                   message: current.message, 
                   distance: totalDist,
                   icon: current.icon
               );
               // Continue loop to check if next instruction can also be merged
               continue;
           } else {
               simplified.add(current);
               current = next;
           }
      }
      simplified.add(current);
      
      // Post-process: Squash Zig-Zags (Turn Left -> Walk 10m -> Turn Left -> Walk 20m => Turn Left -> Walk 30m)
      // This handles curves modeled as multiple segments.
      if (simplified.isNotEmpty) {
           // We need a while loop because we remove items
           int i = 0;
           while (i + 3 < simplified.length) {
               var t1 = simplified[i];     // Turn 1
               var w1 = simplified[i+1];   // Walk 1
               var t2 = simplified[i+2];   // Turn 2
               var w2 = simplified[i+3];   // Walk 2
               
               // Check if pattern matches: Turn X -> Walk -> Turn X -> Walk
               bool isTurn1 = t1.distance == 0 && (t1.icon == 'left' || t1.icon == 'right');
               bool isWalk1 = w1.icon == 'straight';
               bool isTurn2 = t2.distance == 0 && (t2.icon == 'left' || t2.icon == 'right');
               bool isWalk2 = w2.icon == 'straight';
               
               if (isTurn1 && isWalk1 && isTurn2 && isWalk2 && 
                   t1.icon == t2.icon && // Same direction
                   w1.distance < 40 // Squash Zig-Zags up to 40m
                   ) {
                   
                   // MERGE:
                   // 1. Keep t1 (The initial turn)
                   // 2. Update w1 (Combine distances)
                   simplified[i+1] = NavigationInstruction(
                       message: w1.message,
                       distance: w1.distance + w2.distance,
                       icon: w1.icon
                   );
                   // 3. Remove t2 and w2
                   simplified.removeAt(i+3); // Remove w2
                   simplified.removeAt(i+2); // Remove t2
                   
                   // Don't increment i, re-check (in case of triple turn?)
                   continue;
               }
               i++;
           }
      }
      
      return simplified;
  }
  
  // ... (rest of methods)

  /// Determines the turn direction ('left', 'right', 'straight', 'sharp_left', 'sharp_right') based on 3 points.
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
      
      // Increased threshold to 50 to ignore slight bends
      if (degrees > -50 && degrees < 50) return 'straight';
      if (degrees >= 50 && degrees < 160) return 'right';
      if (degrees <= -50 && degrees > -160) return 'left';
      if (degrees >= 160) return 'sharp_right';
      if (degrees <= -160) return 'sharp_left';
      return 'straight'; // Fallback
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

  bool _isVerticalTransition(Room a, Room b, Map<String, int> levels) {
      if (a.connectorId != null && a.connectorId == b.connectorId && a.id != b.id) {
          // Debug
          final levelA = levels[a.floorId];
          final levelB = levels[b.floorId];
          if (levelA != levelB || levelA == null || levelB == null) {
              print('NavService: Vertical Check: ${a.name}(${a.floorId}) vs ${b.name}(${b.floorId})');
              print(' - Levels: $levelA vs $levelB');
          }

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
