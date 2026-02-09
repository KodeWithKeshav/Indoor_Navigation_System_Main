# Sprint 1 Testing Documentation

## Testing Tool: `flutter_test`
The project utilizes `flutter_test`, the standard testing framework provided by the Flutter SDK. It allows for unit, widget, and integration testing with a focus on fast execution and clear diagnostics.

## Modules Tested
### 1. Navigation (Core Logic)
- **PathfindingService**: Verified the A* implementation, including:
    - Basic shortest path calculation.
    - Accessibility constraints (avoiding stairs).
    - Handling of disconnected nodes.
    - Undirected graph traversal.
- **GraphService**: Verified the data-to-graph transformation logic:
    - Correct population of room and corridor data from repositories.
    - Caching and "dirty" state management.
    - Handling of repository failures using `fpdart` `Either` types.

## Test Results
| Total Tests | Passed | Failed |
| ----------- | ------ | ------ |
| 8           | 8      | 0      |

## How to Run Tests
To execute all unit tests, run the following command in the project root:
```bash
flutter test
```

## Mocking Strategy
The project uses `mockito` to isolate services from the `AdminMapRepository`. This ensures that unit tests for logic do not depend on a live Firebase connection or specific database state.
