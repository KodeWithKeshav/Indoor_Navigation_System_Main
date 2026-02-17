# Testing Strategy — Indoor Navigation System

## 1. Overview

| Metric | Value |
|---|---|
| **Total test files** | 35 |
| **Total tests** | ~105 |
| **Unit tests** | 27 files (~61 tests) |
| **Widget tests** | 6 files (~10 tests) |
| **Integration tests** | 2 files (~34 tests) |

---

## 2. Testing Tools

| Tool | Role |
|---|---|
| **`flutter_test`** | Core framework for all unit, widget, and integration tests |
| **`mockito`** | Standard mocking package (code-gen via `build_runner`) — Installed & available |
| **`mocktail`** | Lightweight mocking (no code-gen) — **Currently used** in auth tests |
| **Hand-written fakes** | `FakeAdminMapRepository` and `FakeAuthRepository` in `test/test_utils/fakes.dart` |
| **`flutter_riverpod`** | `ProviderContainer` with `overrides` for isolating state in provider/widget tests |

### How Each Tool Is Used

#### `flutter_test`

Used in **all 35 test files**. Provides `test()`, `group()`, `testWidgets()`, `expect()`, `setUp()`, `tearDown()`, and widget testing utilities.

#### `mockito` vs `mocktail`

Both libraries are installed. The project currently favors **`mocktail`** to avoid code generation steps, but **`mockito`** is available if code generation is preferred for complex mocks.

- **`mocktail` usage**: `class MockAuthRepository extends Mock implements AuthRepository {}` (No `build_runner` needed)
- **`mockito` usage**: `@GenerateMocks([AuthRepository])` (Requires `dart run build_runner build`)

#### `mocktail` Implementation

```dart
// Unit test example (pathfinding_service_test.dart)
test('should find shortest path through multiple rooms', () {
  final path = PathfindingService.findPath('A', 'C', rooms, corridors);
  expect(path, ['A', 'B', 'C']);
});

// Widget test example (auth_screens_test.dart)
testWidgets('LoginScreen renders login header', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [/* provider overrides */],
      child: const MaterialApp(home: LoginScreen()),
    ),
  );
  expect(find.text('SYSTEM LOGIN'), findsOneWidget);
});
```

#### `mocktail`

Used in **3 test files** for mocking repository interfaces:

| Test File | Mock Class | Interface Mocked |
|---|---|---|
| `auth_repository_impl_test.dart` | `_MockAuthRemoteDataSource` | `AuthRemoteDataSource` |
| `login_usecase_test.dart` | `MockAuthRepository` | `AuthRepository` |
| `signup_usecase_test.dart` | `MockAuthRepository` | `AuthRepository` |

```dart
// Mock setup (login_usecase_test.dart)
class MockAuthRepository extends Mock implements AuthRepository {}

setUp(() {
  mockAuthRepository = MockAuthRepository();
  loginUseCase = LoginUseCase(mockAuthRepository);
});

// Stubbing with when() + verifying with verify()
when(() => mockAuthRepository.loginWithEmailPassword(
  email: testEmail, password: testPassword,
)).thenAnswer((_) async => const Right(testUser));

final result = await loginUseCase(LoginParams(email: testEmail, password: testPassword));

expect(result.isRight(), isTrue);
verify(() => mockAuthRepository.loginWithEmailPassword(
  email: testEmail, password: testPassword,
)).called(1);
```

#### Hand-Written Fakes (`test/test_utils/fakes.dart`)

Two shared fake implementations (301 lines) used across multiple test files:

**`FakeAdminMapRepository`** — Full in-memory CRUD for all map entities (Organizations, Buildings, Floors, Rooms, Corridors, CampusConnections). Accepts seed data via constructor. Has `shouldFail` flag for error simulation.

**`FakeAuthRepository`** — In-memory user list with login, signup, logout, role update, and org update. Has `shouldFail` flag.

```dart
// Usage in graph_service_test.dart
final repo = FakeAdminMapRepository(
  buildings: [building],
  floorsByBuilding: {'b1': [floor]},
  roomsByFloor: {'b1-f1': rooms},
  corridorsByFloor: {'b1-f1': corridors},
  campusConnections: const <CampusConnection>[],
);
final service = GraphService(repo);
final result = await service.buildGraph();
expect(result, const Right(null));
```

---

## 3. Test Summary by Component

### Core Pathfinding Engine (14 tests)
- A* shortest path correctness (adjacent, multi-hop, multiple routes)
- Accessibility mode (stairs vs elevator routing)
- Edge cases (empty graph, invalid rooms, single room, large distances)
- **Known bug**: `TypeError` when end room doesn't exist (documented in test)

### Navigation Instruction Service (12 tests)
- Turn-by-turn instruction generation (left, right, straight)
- Vertical transitions (stairs up/down, elevator up/down icons)
- Distance calculation (corridor distance + Euclidean fallback)
- Landmark inclusion in instructions

### Admin Map Module (36 tests)
- Entity construction, equality, and edge cases (Building, Floor, Room, Corridor, CampusConnection, RoomType enum — 19 entity tests)
- Data model Firestore mapping (6 model tests)
- Repository CRUD operations + floor uniqueness (3 repo tests)
- Use case delegation to repository (5 use case tests)
- Integration CRUD scenarios with error handling (32 tests in `indoor_map_data_test.dart`)
- User management controller role update (1 test)

### Authentication Module (33 tests)
- Login use case: success, failure, params, admin role, network error (6 tests)
- Signup use case: success, duplicate email, weak password, invalid email, default role (7 tests)
- User entity: construction, equality by all fields, props (12 tests)
- Data source: null user, valid user retrieval (2 tests)
- Repository: success path, exception→failure mapping (2 tests)
- Model: JSON round-trip, Firestore mapping (2 tests)
- Providers: currentUser state, organizationList fetch (2 tests)

### Navigation UI (1 test)
- `PathArrowPainter.shouldRepaint` identity check

### Widget Tests (10 tests)
- `MyApp` builds with router override (1)
- `LoginScreen`, `SignUpScreen`, `AdminLoginScreen` render headers (3)
- `SplashScreen` loading indicator (1)
- `OrganizationListScreen` structure + FAB (3)
- `UserProfileScreen` organization change flow (1)
- Smoke test placeholder (1)

### Core Infrastructure (7 tests)
- Failure equality, UseCase contract, NoParams, settings toggles, router builds GoRouter, theme brightness, Firebase options platform check

---

## 4. Coverage Targets

| Metric | Target |
|---|---|
| Line coverage | ≥ 80% |
| Branch coverage | ≥ 70% |
| New code | 100% |

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 5. Testing Gaps

| Gap | Details |
|---|---|
| No auth integration test | No end-to-end login → navigate → admin panel test |
| No navigation screen widget tests | Only `PathArrowPainter.shouldRepaint` tested |
| GraphService: 1 test only | No error/edge case coverage |
| VoiceGuidanceService: 1 test only | Only `isSpeaking` toggle, no TTS/error tests |
| `widget_test.dart` placeholder | `expect(1 + 1, 2)` — no widget tested |
| Duplicate fake repository | `indoor_map_data_test.dart` has inline copy of `FakeAdminMapRepository` |
