# Indoor Navigation System Testing Documentation

## Testing Tool: `flutter_test`
The project utilizes `flutter_test`, the standard testing framework provided by the Flutter SDK. It allows for unit, widget, and integration testing with a focus on fast execution and clear diagnostics.

## Modules Tested
### 1. Navigation (Core Logic)
- **PathfindingService**: Verified the A* implementation, including:
    - Basic shortest path calculation.
    - Accessibility constraints (avoiding stairs).
    - Handling of disconnected nodes.
    - Undirected graph traversal.
    - **Multi-Stop Errand Optimization**: Validated the Traveling Salesperson Problem (TSP) logic for nearest-neighbor multi-waypoint routing.
    - **Campus Connections**: Validated cross-building paths with virtual edge penalties.
    - **Out-of-Service Rooms**: Ensured closed rooms are excluded from graph traversals.
- **GraphService**: Verified the data-to-graph transformation logic:
    - Correct population of room and corridor data from repositories.
    - Caching and "dirty" state management.
    - Handling of repository failures using `fpdart` `Either` types.

### 2. Integration Testing
A comprehensive integration test suite verifies end-to-end functionality utilizing Fake repositories (`FakeAdminMapRepository`, `FakeAuthRepository`) to execute without Firebase.
- **Auth Flow**: Validated signup, login, session persistence, logout, and role constraints.
- **Admin Map Management**: Validated the full CRUD pipeline for the entire map hierarchy (Organizations ➝ Buildings ➝ Floors ➝ Rooms/Corridors) with cross-entity constraints.
- **Pathfinding & Navigation**: Integrated `PathfindingService` with `NavigationInstructionService` to verify that A* routes are correctly converted to precise navigation steps and headings.
- **Multi-floor Routing**: Validated vertical translations with Stairs and Elevators utilizing accessible constraints.
- **Failure Propagation**: Exhaustively verified that database/auth failures correctly bubble up from the repository to the usescases and return the expected `Left(Failure)`.

## Test Results
| Total Tests | Passed | Failed |
| ----------- | ------ | ------ |
| 250         | 250    | 0      |

## How to Run Tests
To execute all unit tests, run the following command in the project root:
```bash
flutter test
```

## Mocking Strategy
The project uses `mockito` to isolate services from the `AdminMapRepository`. This ensures that unit tests for logic do not depend on a live Firebase connection or specific database state.
