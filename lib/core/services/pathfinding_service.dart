
import 'dart:collection';
import 'dart:math';
import '../../features/admin_map/domain/entities/map_entities.dart';

/// Service that implements the A* pathfinding algorithm for indoor navigation.
class PathfindingService {
  // A* Algorithm
  /// Finds the shortest path between two rooms using the A* search algorithm.
  /// 
  /// Takes [startId] and [endId] as strings, along with lists of [rooms] and [corridors].
  /// [isAccessible] flag filters out stairs and non-accessible routes if set to true.
  /// Returns a list of Room IDs representing the path from start to end.
  static List<String> findPath(
      String startId, 
      String endId, 
      List<Room> rooms, 
      List<Corridor> corridors, {
      bool isAccessible = false,
  }) {
    // 1. Build Graph
    // Map<RoomId, List<Edge>> where Edge contains neighborId and distance
    final Map<String, List<Corridor>> adj = {};
    final Map<String, Room> roomMap = {for (var r in rooms) r.id: r};
    
    // Initialize adj
    for (var r in rooms) {
      adj[r.id] = [];
    }
    
    for (var c in corridors) {
      if (roomMap.containsKey(c.startRoomId) && roomMap.containsKey(c.endRoomId)) {
        adj[c.startRoomId]?.add(c);
        adj[c.endRoomId]?.add(c); // Undirected (same corridor object used for both directions)
      }
    }
    
    // 2. Setup Priority Queue and Tracking
    // Using a simple List and sorting for Priority Queue behavior (efficient enough for small graphs < 1000 nodes)
    final openSet = <String>[startId];
    final cameFrom = <String, String>{};
    
    // gScore: cost from start to node
    final gScore = <String, double>{startId: 0.0};
    
    // fScore: gScore + heuristic (dist to end)
    final fScore = <String, double>{};
    if (roomMap.containsKey(startId) && roomMap.containsKey(endId)) {
       fScore[startId] = _heuristic(roomMap[startId]!, roomMap[endId]!);
    }
    
    while (openSet.isNotEmpty) {
      // Get node with lowest fScore
      openSet.sort((a, b) => (fScore[a] ?? double.infinity).compareTo(fScore[b] ?? double.infinity));
      final current = openSet.removeAt(0);
      
      if (current == endId) {
        return _reconstructPath(cameFrom, current);
      }
      
      final neighborCorridors = adj[current] ?? [];
      for (var corridor in neighborCorridors) {
        final neighborId = (corridor.startRoomId == current) ? corridor.endRoomId : corridor.startRoomId;
        final neighborRoom = roomMap[neighborId];

        // Accessibility Check: Skip Stairs if isAccessible is true
        if (isAccessible && neighborRoom != null && neighborRoom.type == RoomType.stairs) {
           continue; 
        }
        
        // Use defined corridor distance
        final dist = corridor.distance;
        final tentativeGScore = (gScore[current] ?? double.infinity) + dist;
        
        if (tentativeGScore < (gScore[neighborId] ?? double.infinity)) {
          cameFrom[neighborId] = current;
          gScore[neighborId] = tentativeGScore;
          fScore[neighborId] = tentativeGScore + _heuristic(roomMap[neighborId]!, roomMap[endId]!);
          
          if (!openSet.contains(neighborId)) {
            openSet.add(neighborId);
          }
        }
      }
    }
    
    return []; // No path found
  }
  
  
  /// Heuristic function for A* (Euclidean distance).
  ///
  /// Returns 0 for multi-floor transitions to ensure admissibility (like Dijkstra).
  static double _heuristic(Room a, Room b) {
    // If on different floors/buildings, we can't use 2D Euclidean distance safely 
    // because coordinate systems might differ or overlap physically.
    // Return 0 (Dijkstra behavior) for multi-floor heuristic to be admissible.
    if (a.floorId != b.floorId) {
      return 0.0;
    }
    
    // Same floor: Euclidean distance
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }
  
  
  /// Reconstructs the path from the [cameFrom] map.
  ///
  /// Backtracks from [current] (end node) to the start node.
  static List<String> _reconstructPath(Map<String, String> cameFrom, String current) {
    final path = <String>[current];
    while (cameFrom.containsKey(current)) {
      current = cameFrom[current]!;
      path.insert(0, current);
    }
    return path; 
  }
}
