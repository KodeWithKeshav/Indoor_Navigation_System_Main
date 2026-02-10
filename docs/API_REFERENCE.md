# API Reference

This document provides a reference for the core services and providers used in the **Indoor Navigation System**.

## Core Services

### PathfindingService

The `PathfindingService` is responsible for calculating the shortest path between two points in the indoor graph.

#### `findPath`

Calculates the optimal route between a start and end node.

```dart
Future<Either<Failure, RoutePath>> findPath({
  required String startNodeId,
  required String endNodeId,
  bool accessible = false, // Avoid stairs if true
})
```

- **Parameters**: 
  - `startNodeId`: Unique identifier of the starting room/node.
  - `endNodeId`: Unique identifier of the destination room/node.
  - `accessible`: Boolean flag to enable wheelchair-accessible routing.
- **Returns**: `Right(RoutePath)` on success, or `Left(Failure)` if no path is found.

### GraphService

Manages the construction and caching of the navigation graph from Firestore data.

#### `buildGraph`

Fetches all map data and constructs the weighted graph.

```dart
Future<void> buildGraph();
```

- **Description**: Loads buildings, floors, rooms, and connections to build the in-memory graph used by `PathfindingService`. Should be called on app startup or when map data changes.

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

### GraphNode

Represents a point on the map.

```dart
class GraphNode {
  final String id;
  final String name;
  final NodeType type; // room, corridor, stair, elevator
  final Coordinates position;
}
```

## Error Handling

The application uses `Failure` classes for error handling.

- `ServerFailure`: Issues with Firebase/Network.
- `CacheFailure`: Issues with local storage.
- `PathNotFoundFailure`: No valid path exists between nodes.
- `InvalidInputFailure`: Bad data provided to a function.
