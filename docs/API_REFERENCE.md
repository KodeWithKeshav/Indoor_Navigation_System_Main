# API Reference

This document provides a reference for the core services and providers used in the **Indoor Navigation System**.

## Core Services

### PathfindingService

The `PathfindingService` is responsible for calculating the shortest path between two points in the indoor graph.

#### `findPath`

Calculates the optimal route between a start and end node.

```dart
List<String> findPath(
  String startRoomId,
  String endRoomId,
  List<Room> rooms,
  List<Corridor> corridors, {
  bool isAccessible = false,
})
```

- **Parameters**: 
  - `startRoomId`: Unique identifier of the starting room.
  - `endRoomId`: Unique identifier of the destination room.
  - `rooms`: Complete list of available rooms (nodes).
  - `corridors`: Complete list of corridors/connections (edges).
  - `isAccessible`: Boolean flag to enable wheelchair-accessible routing (avoids stairs).
- **Returns**: A list of room IDs forming the shortest path. Empty if unreachable.

#### `findTSPPath`

Calculates the optimal order to visit multiple waypoints before reaching the destination (Traveling Salesperson Problem).

```dart
List<String> findTSPPath(
  String startId,
  List<String> waypoints,
  String endId,
  List<Room> rooms,
  List<Corridor> corridors, {
  bool isAccessible = false,
})
```

- **Parameters**: 
  - `startId`: The starting room.
  - `waypoints`: List of intermediate room IDs to visit.
  - `endId`: The final destination room.
  - `rooms` & `corridors`: Map data.
  - `isAccessible`: Accessibility constraint.
- **Returns**: An ordered list of room IDs forming the most efficient multi-stop route.

### GraphService

Manages the construction and caching of the navigation graph from Firestore data.

#### `buildGraph`

Fetches all map data and constructs the weighted graph.

```dart
Future<void> buildGraph();
```

- **Description**: Loads buildings, floors, rooms, and campus connections to build the in-memory graph used by `PathfindingService`. Should be called on app startup or when map data changes. Handles virtual edge creation for multi-building routes.

#### `getGraph`

Returns the current in-memory graph.

```dart
Graph getGraph();
```

## Repositories

### BuildingRepository

Handles data operations for buildings.

- `getBuildings(orgId)`: Fetch all buildings for an organization.
- `addBuilding(building)`: Create a new building.
- `updateBuilding(building)`: Update existing building details.
- `deleteBuilding(buildingId)`: Remove a building and its floors.

### CampusConnectionRepository

Handles connections between distinct buildings.

- `getCampusConnections()`: Fetch all cross-building virtual edges.
- `addCampusConnection(connection)`: Create a path between two buildings.
- `deleteCampusConnection(connectionId)`: Remove a building link.

### RoomRepository

Handles data operations for rooms.

- `getRooms(floorId)`: Fetch all rooms on a specific floor.
- `searchRooms(query)`: Search for rooms by name or number across the campus.

## Models

### RoutePath

Represents a calculated navigation path.

```dart
class RoutePath {
  final List<GraphNode> nodes;
  final double totalDistance;
  final Duration estimatedTime;
  
  // Helpers
  List<String> get instructions; // Textual navigation steps
}
```

```dart
class Room {
  final String id;
  final String floorId;
  final String name;
  final RoomType type; // room, corridor, stair, elevator, entrance
  final double x;
  final double y;
  final bool isClosed; // True if Out of Service (excluded from pathfinding)
}
```

### CampusConnection

Represents a routable connection between two different buildings.

```dart
class CampusConnection {
  final String id;
  final String fromBuildingId;
  final String toBuildingId;
  final double distance; // Base penalty added when generating virtual edge
}
```

## Error Handling

The application uses `Failure` classes for error handling.

- `ServerFailure`: Issues with Firebase/Network.
- `CacheFailure`: Issues with local storage.
- `PathNotFoundFailure`: No valid path exists between nodes.
- `InvalidInputFailure`: Bad data provided to a function.
