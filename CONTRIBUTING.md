# Contributing to Indoor Navigation System

First off, thank you for considering contributing to the Indoor Navigation System! 🎉

It's people like you that make this project a great tool for indoor wayfinding. We welcome contributions from everyone, whether you're fixing a typo, reporting a bug, or implementing a major feature.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Contributing Code](#contributing-code)
  - [Improving Documentation](#improving-documentation)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Project Structure](#project-structure)
- [Getting Help](#getting-help)

---

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

---

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the [existing issues](https://github.com/KodeWithKeshav/Indoor_Navigation_System_Main/issues) to avoid duplicates.

When you create a bug report, include as many details as possible:

1. **Use the bug report template** when creating an issue
2. **Use a clear and descriptive title**
3. **Describe the exact steps to reproduce the problem**
4. **Provide specific examples** (code snippets, screenshots)
5. **Describe the behavior you observed** and what you expected
6. **Include environment details**:
   - Flutter version (`flutter --version`)
   - Device/emulator information
   - Operating system
   - Firebase configuration (if relevant)

### Suggesting Features

Feature suggestions are tracked as [GitHub issues](https://github.com/KodeWithKeshav/Indoor_Navigation_System_Main/issues).

When suggesting a feature:

1. **Use the feature request template**
2. **Provide a clear use case** - explain why this feature would be useful
3. **Describe the proposed solution** in detail
4. **Consider alternatives** you've thought about
5. **Include mockups or diagrams** if applicable

### Contributing Code

We actively welcome your pull requests! Here's the process:

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following our coding standards
3. **Add tests** if you've added code that should be tested
4. **Update documentation** if you've changed APIs or functionality
5. **Ensure all tests pass** (`flutter test`)
6. **Submit a pull request**

### Improving Documentation

Documentation improvements are always welcome! This includes:

- Fixing typos or grammatical errors
- Adding examples or clarifications
- Improving API documentation
- Creating tutorials or guides
- Translating documentation

---

## Development Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/Indoor_Navigation_System_Main.git
cd Indoor_Navigation_System_Main

# Add upstream remote
git remote add upstream https://github.com/KodeWithKeshav/Indoor_Navigation_System_Main.git
```

### 2. Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Generate code (for Riverpod providers, JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Firebase Setup

For development, you'll need your own Firebase project:

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Authentication (Email/Password) and Firestore
3. Download configuration files:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`
4. Or use FlutterFire CLI:
   ```bash
   flutterfire configure
   ```

### 4. Run the App

```bash
# Check for issues
flutter doctor

# Run on connected device
flutter run

# Run in debug mode with hot reload
flutter run --debug
```

---

## Coding Standards

### Dart Style Guide

We follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style) with these key points:

#### Naming Conventions

```dart
// Classes, enums, typedefs: UpperCamelCase
class PathfindingService {}
enum NavigationMode {}

// Libraries, packages, directories, files: lowercase_with_underscores
import 'package:indoor_navigation_system/core/services/graph_service.dart';

// Variables, functions, parameters: lowerCamelCase
String calculateDistance() {}
final currentLocation = Location();

// Constants: lowerCamelCase
const maxPathLength = 1000;

// Private members: prefix with underscore
class _PrivateClass {}
void _privateMethod() {}
```

#### Code Formatting

```bash
# Format all Dart files
dart format .

# Check formatting without making changes
dart format --output=none --set-exit-if-changed .
```

#### Linting

We use `flutter_lints` for static analysis:

```bash
# Run analyzer
flutter analyze

# Fix auto-fixable issues
dart fix --apply
```

### Flutter Best Practices

1. **Widget Organization**
   ```dart
   // Break down large widgets into smaller, reusable components
   class TripPlannerWidget extends ConsumerWidget {
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       return Column(
         children: [
           _buildHeader(),
           _buildLocationSelector(),
           _buildActionButtons(),
         ],
       );
     }
   }
   ```

2. **State Management**
   - Use Riverpod for state management
   - Keep providers in separate files
   - Use code generation for providers when possible

3. **Error Handling**
   ```dart
   // Use fpdart Either for error handling
   Future<Either<Failure, List<Room>>> getRooms() async {
     try {
       final rooms = await repository.fetchRooms();
       return right(rooms);
     } catch (e) {
       return left(ServerFailure(e.toString()));
     }
   }
   ```

4. **Dependency Injection**
   - Register services in `main.dart` using GetIt
   - Use constructor injection
   - Avoid service locator pattern in widgets (use Riverpod)

### Documentation

#### Code Comments

```dart
/// Calculates the shortest path between two nodes using A* algorithm.
///
/// The [start] and [end] parameters must be valid node IDs in the graph.
/// Returns a [PathResult] containing the path and distance, or an error.
///
/// Example:
/// ```dart
/// final result = await pathfindingService.findPath(
///   start: 'room_101',
///   end: 'room_205',
/// );
/// ```
Future<PathResult> findPath({
  required String start,
  required String end,
}) async {
  // Implementation
}
```

#### File Headers

```dart
/// File: pathfinding_service.dart
/// Purpose: A* pathfinding algorithm implementation for indoor navigation
/// Author: Indoor Navigation System Team
/// Last Modified: 2026-02-10
```

---

## Commit Message Guidelines

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, no logic change)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks (dependencies, build config)
- **perf**: Performance improvements

### Examples

```bash
# Feature
git commit -m "feat(navigation): add voice-guided navigation support"

# Bug fix
git commit -m "fix(pathfinding): correct A* heuristic calculation for multi-floor paths"

# Documentation
git commit -m "docs(readme): add troubleshooting section for Firebase setup"

# Breaking change
git commit -m "feat(api)!: change PathfindingService interface

BREAKING CHANGE: findPath() now returns Future<Either<Failure, Path>> instead of Future<Path>"
```

### Scope

Common scopes in this project:
- `navigation`: User navigation features
- `admin`: Admin map management
- `auth`: Authentication
- `pathfinding`: Pathfinding algorithm
- `ui`: UI components
- `core`: Core services and utilities
- `test`: Testing infrastructure

---

## Pull Request Process

### Before Submitting

1. **Update from upstream**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run tests**
   ```bash
   flutter test
   ```

3. **Check code quality**
   ```bash
   flutter analyze
   dart format .
   ```

4. **Update documentation** if needed

### PR Template

When you create a PR, fill out the template completely:

- **Description**: What does this PR do?
- **Related Issue**: Link to the issue (e.g., "Fixes #123")
- **Type of Change**: Bug fix, feature, documentation, etc.
- **Testing**: How did you test this?
- **Screenshots**: For UI changes
- **Checklist**: Confirm all items are complete

### Review Process

1. **Automated checks** must pass (tests, linting)
2. **At least one maintainer** must approve
3. **All review comments** must be addressed
4. **Squash and merge** is preferred for clean history

### After Merge

- Delete your feature branch
- Update your local repository:
  ```bash
  git checkout main
  git pull upstream main
  ```

---

## Testing Requirements

### Test Coverage

- **New features**: Must include unit tests
- **Bug fixes**: Should include regression tests
- **Minimum coverage**: Aim for 80%+ on new code

### Writing Tests

```dart
// Unit test example
void main() {
  group('PathfindingService', () {
    late PathfindingService service;
    late MockGraphService mockGraph;

    setUp(() {
      mockGraph = MockGraphService();
      service = PathfindingService(mockGraph);
    });

    test('should find shortest path between connected nodes', () async {
      // Arrange
      when(mockGraph.getGraph()).thenReturn(testGraph);

      // Act
      final result = await service.findPath(
        start: 'A',
        end: 'B',
      );

      // Assert
      expect(result.isRight(), true);
      expect(result.getOrElse(() => []), ['A', 'B']);
    });
  });
}
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/core/services/pathfinding_service_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Project Structure

Understanding the project structure will help you navigate the codebase:

```
lib/
├── core/                   # Shared utilities
│   ├── services/          # Core services (pathfinding, graph)
│   ├── theme/             # App theming
│   └── utils/             # Helper functions
│
├── features/              # Feature modules (Clean Architecture)
│   ├── admin_map/
│   │   ├── data/          # Repositories, data sources
│   │   ├── domain/        # Entities, use cases
│   │   └── presentation/  # UI, controllers, providers
│   │
│   ├── navigation/        # User navigation
│   ├── auth/              # Authentication
│   └── accessibility/     # Accessibility features
│
└── main.dart              # App entry point

test/                      # Mirror structure of lib/
docs/                      # Documentation
```

---

## Getting Help

### Resources

- **Documentation**: [README.md](README.md), [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/KodeWithKeshav/Indoor_Navigation_System_Main/issues)
- **Discussions**: [GitHub Discussions](https://github.com/KodeWithKeshav/Indoor_Navigation_System_Main/discussions)

### Questions?

- Check existing [GitHub Discussions](https://github.com/KodeWithKeshav/Indoor_Navigation_System_Main/discussions)
- Open a new discussion for general questions
- Use issues only for bugs and feature requests

---

## Recognition

Contributors will be recognized in:
- The project README
- Release notes for significant contributions
- Our hearts ❤️

---

## License

By contributing, you agree that your contributions will be licensed under the same [MIT License](LICENSE.md) that covers this project.

---

**Thank you for contributing to Indoor Navigation System!** 🚀
