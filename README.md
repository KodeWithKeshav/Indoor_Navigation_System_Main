# Indoor Navigation System

A comprehensive Flutter-based indoor navigation application designed to help users navigate buildings with accessibility-first approach. Features role-based access for regular users and administrators, multi-building support, and advanced pathfinding with accessibility considerations.

## 📋 Table of Contents

- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Contributing](#-contributing)

## ✨ Features

### User Features
- **Interactive Maps**: View building layouts with multiple floors
- **Trip Planning**: Select start and destination locations
- **Pathfinding**: A* algorithm-based shortest path calculation
- **Accessibility Mode**: Routes that avoid stairs/prioritize elevators
- **Turn-by-Turn Navigation**: Step-by-step text and visual instructions
- **Voice Guidance**: Audio directions for hands-free navigation
- **Theme Customization**: Dark mode and high-contrast accessibility themes
- **Text Scaling**: Adjustable text sizes for readability

### Admin Features
- **Building Management**: Create and manage multiple buildings
- **Floor Planning**: Design floors with customizable layouts
- **Room Configuration**: Define room types (entrance, hallway, stairs, elevator, etc.)
- **Corridor Management**: Draw connections between rooms with custom distances
- **Campus Maps**: Support for campus-wide navigation across buildings
- **Organization Management**: Multi-tenant support for different organizations
- **Navigation Testing**: Test pathfinding in real-time

## 🛠 Tech Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter (Dart 3.9+) |
| **State Management** | Flutter Riverpod 3.1.0 |
| **Navigation** | GoRouter 17.0.1 |
| **Backend** | Firebase (Core, Auth, Firestore) |
| **Authentication** | Firebase Auth 6.1.3 |
| **Database** | Cloud Firestore 6.1.1 |
| **Code Generation** | build_runner, riverpod_generator |
| **UI Framework** | Material Design |
| **Fonts** | Google Fonts 7.0.2 |
| **Dependency Injection** | GetIt 9.2.0 |
| **Functional Programming** | fpdart 1.2.0 |

## 🏗 Architecture

This project follows **Clean Architecture** principles:

### Layers
1. **Domain Layer**: Business logic, entities, and use cases
   - Independent of frameworks
   - Contains core application logic
   
2. **Data Layer**: Data sources, repositories, and models
   - Firebase integration
   - Repository implementations
   
3. **Presentation Layer**: UI screens, providers, and widgets
   - Flutter widgets
   - State management with Riverpod

### Design Patterns
- **Repository Pattern**: Abstraction for data access
- **Dependency Injection**: GetIt service locator
- **State Management**: Riverpod providers for reactive state
- **Router Pattern**: GoRouter for navigation management

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
│
├── core/                     # Shared functionality
│   ├── router/
│   │   └── router.dart      # GoRouter configuration & routes
│   ├── services/
│   │   ├── pathfinding_service.dart          # A* pathfinding algorithm
│   │   ├── graph_service.dart                # Building graph management
│   │   ├── navigation_instruction_service.dart # Route instructions
│   │   └── voice_guidance_service.dart       # Text-to-speech
│   ├── providers/
│   │   └── settings_provider.dart            # Accessibility settings
│   ├── theme/
│   │   └── app_theme.dart                    # Material theme configuration
│   ├── widgets/
│   │   └── splash_screen.dart                # App splash screen
│   └── errors/
│       └── exceptions.dart                    # Custom exceptions
│
├── features/
│   │
│   ├── auth/                # Authentication feature
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart
│   │   │   └── repositories/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── login_screen.dart
│   │       │   ├── signup_screen.dart
│   │       │   └── admin_login_screen.dart
│   │       └── providers/
│   │           ├── auth_providers.dart
│   │           └── auth_controller.dart
│   │
│   ├── admin_map/           # Admin map management
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── map_entities.dart
│   │   │   └── usecases/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── admin_dashboard_screen.dart
│   │       │   ├── building_detail_screen.dart
│   │       │   ├── floor_detail_screen.dart
│   │       │   ├── user_management_screen.dart
│   │       │   └── organization_list_screen.dart
│   │       ├── providers/
│   │       │   └── admin_map_providers.dart
│   │       └── widgets/
│   │
│   └── navigation/          # User navigation feature
│       ├── domain/
│       ├── presentation/
│       │   ├── pages/
│       │   │   └── user_home_screen.dart
│       │   ├── providers/
│       │   │   ├── navigation_provider.dart
│       │   │   └── user_location_provider.dart
│       │   └── widgets/
│       │       ├── path_arrow_painter.dart      # Path visualization
│       │       └── trip_planner_widget.dart     # Trip planning UI
│
test/                        # Unit tests
└── integration_test/        # Integration tests
```

## 🚀 Installation

### Prerequisites
- Flutter SDK (3.9.0 or higher)
- Dart SDK (included with Flutter)
- Firebase project setup
- Git

### Setup Steps

1. **Clone the repository**
```bash
git clone <repository-url>
cd Indoor_Navigation_System
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Firebase**
   - Create a Firebase project at [firebase.google.com](https://firebase.google.com)
   - Enable Authentication (Email/Password)
   - Enable Cloud Firestore
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update `firebase_options.dart` with your Firebase config

4. **Code generation**
```bash
flutter pub run build_runner build
```

5. **Run the app**
```bash
# Web
flutter run -d web

# Android
flutter run -d android

# iOS
flutter run -d ios
```

## ⚙️ Configuration

### Firebase Setup

1. **Android** (`android/app/build.gradle`)
   - Ensure `minSdkVersion` is 21 or higher
   
2. **iOS** (`ios/Podfile`)
   - Platform target iOS 12.0 or higher

3. **Web** (default configured)
   - Firebase JS SDK auto-initialized

### Environment Variables
Create `.env` file if needed:
```
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
```

## 💻 Usage

### For Users

1. **Launch the app** and authenticate
2. **Select building** from trip planner
3. **Select floor** and destination room
4. **Enable accessibility** if needed
5. **Follow turn-by-turn directions**
6. **Use voice guidance** (optional)

### For Admins

1. **Login with admin credentials**
2. **Create organizations** (if needed)
3. **Add buildings** to organization
4. **Define floors** within buildings
5. **Create rooms** with appropriate types
6. **Connect rooms** with corridors
7. **Test navigation** using nav mode

## 🧪 Testing

### Unit Tests

Run all tests:
```bash
flutter test
```

Run specific test file:
```bash
flutter test test/core/services/pathfinding_service_test.dart
```

### Test Coverage

```bash
flutter test --coverage
lcov --list-summary coverage/lcov.info
```

### Test Files

- `test/pathfinding_accessibility_test.dart` - Pathfinding with accessibility
- `test/widget_test.dart` - Widget tests

### Adding New Tests

Tests follow the pattern:
```dart
void main() {
  group('Feature Name', () {
    test('Should do something', () {
      // Arrange
      // Act
      // Assert
    });
  });
}
```

## 📦 Key Services

### PathfindingService
Implements A* algorithm for finding shortest paths while respecting accessibility constraints.

**Key Methods:**
```dart
static List<String> findPath(
  String startId,
  String endId,
  List<Room> rooms,
  List<Corridor> corridors,
  {bool isAccessible = false}
);
```

### NavigationInstructionService
Converts room paths into human-readable turn-by-turn instructions.

### GraphService
Manages building graph structure and caches data for performance.

### VoiceGuidanceService
Provides text-to-speech navigation instructions.

## 🚢 Deployment

### Web Deployment

```bash
flutter build web
# Deploy the `build/web` folder to your hosting service
```

### Android Deployment

```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

### iOS Deployment

```bash
flutter build ios --release
# Open in Xcode and archive for App Store
```

## 🤝 Contributing

### Development Workflow

1. Create feature branch: `git checkout -b feature/feature-name`
2. Make changes and test locally
3. Run tests: `flutter test`
4. Run code generation: `flutter pub run build_runner build`
5. Commit: `git commit -am 'Add feature'`
6. Push: `git push origin feature/feature-name`
7. Create Pull Request

### Code Style

- Follow Dart conventions
- Use `flutter analyze` to check code quality
- Format code: `dart format lib/`
- Maximum line length: 80 characters

### Commit Messages

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `test:` Test addition
- `refactor:` Code refactoring
- `style:` Code style changes

## 📝 Version History

- **v1.0.0** - Initial release
  - Core navigation features
  - Admin map management
  - Accessibility features

## 📄 License

This project is licensed under the MIT License.

## 🆘 Troubleshooting

### Firebase Connection Issues
- Verify Firebase project credentials in `firebase_options.dart`
- Check Firebase rules allow read/write access
- Enable required Firebase services in console

### Pathfinding Not Working
- Ensure rooms and corridors are properly connected
- Check room IDs match between definitions
- Verify floor IDs are consistent

### Web Build Fails
- Clear build: `flutter clean`
- Rebuild pub: `flutter pub get`
- Run code generation: `flutter pub run build_runner clean && flutter pub run build_runner build`

## 📧 Support

For issues or questions:
1. Check existing GitHub issues
2. Create detailed bug report with reproduction steps
3. Include device/platform information
4. Attach relevant logs

---

**Last Updated**: January 2026
