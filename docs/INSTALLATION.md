# Installation Guide

This detailed guide will help you set up the **Indoor Navigation System** development environment on your local machine.

## Prerequisites

Before starting, ensure you have the following installed:

1. **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
   - Version: 3.9.0 or higher
   - Verify with: `flutter --version`

2. **Git**: [Install Git](https://git-scm.com/downloads)
   - Verify with: `git --version`

3. **Code Editor**:
   - [VS Code](https://code.visualstudio.com/) (Recommended) with [Flutter Extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
   - [Android Studio](https://developer.android.com/studio) with Flutter Plugin

## Step-by-Step Installation

### 1. Clone the Repository

Open your terminal and run:

```bash
git clone https://github.com/KodeWithKeshav/Indoor_Navigation_System_Main.git
cd Indoor_Navigation_System_Main
```

### 2. Install Dependencies

Fetch all the required Dart packages:

```bash
flutter pub get
```

### 3. Firebase Configuration

The application relies on Firebase for authentication and database services. You need to configure it with your own Firebase project.

#### Option A: Using FlutterFire CLI (Recommended)

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

3. Configure the app:
   ```bash
   flutterfire configure
   ```
   - Select your Firebase project (or create a new one)
   - Select the platforms you want to support (Android, iOS, macOS, Web)
   - This command will automatically generate `lib/firebase_options.dart` and download configuration files.

#### Option B: Manual Configuration

**Android**:
1. Create an app in Firebase Console with package name: `com.example.indoor_navigation_system`
2. Download `google-services.json`
3. Place it in `android/app/google-services.json`

**iOS**:
1. Create an app with bundle ID: `com.example.indoorNavigationSystem`
2. Download `GoogleService-Info.plist`
3. Place it in `ios/Runner/GoogleService-Info.plist`

### 4. Code Generation

Run the build runner to generate necessary files (Riverpod providers, JSON serialization):

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Running the Application

### Android
- Ensure an emulator is running or a physical device is connected.
- Run: `flutter run`

### iOS (macOS only)
- Ensure Xcode is installed.
- Install CocoaPods dependencies:
  ```bash
  cd ios
  pod install
  cd ..
  ```
- Run: `flutter run`

### Troubleshooting

#### Issue: "CocoaPods not installed"
**Fix**: Run `sudo gem install cocoapods` followed by `pod setup`.

#### Issue: "Gradle build failed"
**Fix**: Check your Java JDK version. Flutter typically requires JDK 11 or 17.
- Check current version: `java -version`
- Update `android/gradle.properties` if needed.

#### Issue: "google-services.json missing"
**Fix**: Ensure you have downloaded the configuration file from Firebase Console and placed it in the correct directory.
