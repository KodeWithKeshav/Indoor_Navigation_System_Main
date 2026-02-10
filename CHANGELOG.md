# Changelog

All notable changes to the **Indoor Navigation System** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-10

### Added
- **Admin Map Management**: Complete CRUD operations for buildings, floors, rooms, and corridors.
- **Pathfinding Engine**: Custom A* algorithm implementation with multi-floor support.
- **User Navigation**:
  - Trip planner widget with search and browse functionality.
  - Step-by-step navigation instructions.
  - Visual cues for stairs, elevators, and turns.
- **Authentication**:
  - Role-based login (Admin, Student, Guest) using Firebase Auth.
  - Protected routes for admin features.
- **Accessibility**:
  - Basic stair avoidance logic in pathfinding.
  - Integration of accessibility attributes in map data.
- **UI/UX**:
  - Modern "Deep Void" dark theme with glassmorphism elements.
  - Responsive layout for mobile devices.
  - "Recent Locations" feature for quick access.

### Changed
- Refactored `PathfindingService` to support weighted graphs for better route optimization.
- Updated `GraphService` to cache graph data for improved performance.
- Improved error handling in Firestore repositories using `fpdart`.

### Security
- Implemented Firestore security rules to restrict write access to admins.
- Secured API key usage in configuration.

---

## [0.1.0] - 2026-01-15

### Added
- Initial project structure with Clean Architecture.
- Basic Firebase connectivity.
- Prototype of the A* algorithm.
