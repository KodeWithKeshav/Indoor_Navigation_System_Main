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
      if (roomMap.containsKey(c.startRoomId) &&
          roomMap.containsKey(c.endRoomId)) {
        adj[c.startRoomId]?.add(c);
        adj[c.endRoomId]?.add(
          c,
        ); // Undirected (same corridor object used for both directions)
      }
    }

    // 2. Setup Priority Queue, Closed Set, and Tracking
    final openSet = <String>[startId];
    final closedSet = <String>{}; // Nodes already fully expanded
    final cameFrom = <String, String>{};

    // gScore: cost from start to node
    final gScore = <String, double>{startId: 0.0};

    // fScore: gScore + heuristic (dist to end)
    final fScore = <String, double>{};
    if (roomMap.containsKey(startId) && roomMap.containsKey(endId)) {
      fScore[startId] = _heuristic(roomMap[startId]!, roomMap[endId]!);
    } else {
      print(
        'PathfindingService: Start ($startId) or End ($endId) not in graph!',
      );
      if (!roomMap.containsKey(startId)) print(' - Missing Start');
      if (!roomMap.containsKey(endId)) print(' - Missing End');
      return [];
    }

    while (openSet.isNotEmpty) {
      // Get node with lowest fScore
      openSet.sort(
        (a, b) => (fScore[a] ?? double.infinity).compareTo(
          fScore[b] ?? double.infinity,
        ),
      );
      final current = openSet.removeAt(0);

      if (current == endId) {
        final path = _reconstructPath(cameFrom, current);
        final pathNames = path.map((id) => roomMap[id]?.name ?? id).toList();
        final totalCost = gScore[endId] ?? -1;
        print(
          'PathfindingService: ${roomMap[startId]?.name} → ${roomMap[endId]?.name} | Cost: $totalCost | Path: ${pathNames.join(" → ")}',
        );
        return path;
      }

      // Mark as fully expanded — never revisit
      closedSet.add(current);

      final neighborCorridors = adj[current] ?? [];

      for (var corridor in neighborCorridors) {
        final neighborId = (corridor.startRoomId == current)
            ? corridor.endRoomId
            : corridor.startRoomId;

        final neighborRoom = roomMap[neighborId];
        final currentRoom = roomMap[current];

        if (neighborRoom == null || currentRoom == null) continue;

        // Accessibility Check: Only skip Stairs if it's a VERTICAL transition
        // This allows users to walk "past" or "through" a stair node on the same floor without climbing.
        if (isAccessible) {
          final isVertical = currentRoom.floorId != neighborRoom.floorId;
          if (isVertical &&
              (currentRoom.type == RoomType.stairs ||
                  neighborRoom.type == RoomType.stairs)) {
            continue;
          }
        }

        // Use defined corridor distance
        double dist = corridor.distance;

        // Penalize virtual edges (campus connections) heavily to prefer detailed paths
        if (corridor.id.startsWith('virtual_')) {
          dist *= 3.0;
        }

        final tentativeGScore = (gScore[current] ?? double.infinity) + dist;

        // Skip closed nodes ONLY if we can't improve their g-score.
        // The heuristic is inconsistent across floors (h=0 for cross-floor, h=Euclidean for same-floor),
        // so closed nodes must be re-opened when a cheaper path is discovered.
        if (closedSet.contains(neighborId) &&
            tentativeGScore >= (gScore[neighborId] ?? double.infinity)) {
          continue;
        }

        if (tentativeGScore < (gScore[neighborId] ?? double.infinity)) {
          // Re-open if previously closed with a worse cost
          closedSet.remove(neighborId);

          cameFrom[neighborId] = current;
          gScore[neighborId] = tentativeGScore;
          fScore[neighborId] =
              tentativeGScore +
              _heuristic(roomMap[neighborId]!, roomMap[endId]!);

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
    // SCALE FACTOR: 0.05 (Assuming ~20 pixels = 1 meter)
    // Heuristic must be admissible (h <= true cost). Without scaling, pixel distance (700)
    // vastly exceeds meter cost (50), causing A* to overestimate and degrade to greedy search.
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2)) * 0.05;
  }

  /// Reconstructs the path from the [cameFrom] map.
  ///
  /// Backtracks from [current] (end node) to the start node.
  static List<String> _reconstructPath(
    Map<String, String> cameFrom,
    String current,
  ) {
    final path = <String>[current];
    while (cameFrom.containsKey(current)) {
      current = cameFrom[current]!;
      path.insert(0, current);
    }
    return path;
  }
}
