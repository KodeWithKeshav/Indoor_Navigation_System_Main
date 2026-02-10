# Deployment Guide

This guide explains how to build and deploy the **Indoor Navigation System** for testing and production.

## 📱 Android Deployment

### 1. Configure Signing
To publish to the Play Store or distribute a release APK, you need to sign your app.

1. **Create a keystore**:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. **Create `android/key.properties`**:
   ```properties
   storePassword=<your-store-password>
   keyPassword=<your-key-password>
   keyAlias=upload
   storeFile=~/upload-keystore.jks
   ```
3. **Update `android/app/build.gradle`** to use the keystore for release builds.

### 2. Build APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### 3. Build App Bundle (AAB)
Required for Play Store submission.
```bash
flutter build appbundle
```
Output: `build/app/outputs/bundle/release/app-release.aab`

## 🍎 iOS Deployment (macOS only)

### 1. Prerequisites
- Apple Developer Account
- Certified signing certificate installed in Keychain
- Provisioning profile

### 2. Build for Archive
```bash
flutter build ipa
```
Output: `build/ios/archive/Runner.xcarchive`

### 3. Upload to TestFlight
1. Open `build/ios/archive/Runner.xcarchive` in Xcode.
2. Click "Distribute App".
3. Select "App Store Connect" -> "Upload".
4. Follow the wizard to upload.

## 🌐 Web Deployment

### 1. Build for Production
```bash
flutter build web --release
```
Output: `build/web/`

### 2. Host
Deploy the contents of `build/web/` to any static hosting service:
- **Firebase Hosting** (Recommended):
  ```bash
  firebase init hosting
  firebase deploy
  ```
- **GitHub Pages**
- **Vercel / Netlify**

## 🖥 Desktop Deployment

### macOS
```bash
flutter build macos
```
Output: `build/macos/Build/Products/Release/indoor_navigation_system.app`

### Windows
```bash
flutter build windows
```
Output: `build/windows/runner/Release/`

### Linux
```bash
flutter build linux
```
Output: `build/linux/x64/release/bundle/`

## 🔄 CI/CD Pipeline (GitHub Actions)

This project includes a basic GitHub Actions workflow for automated testing and building.

**Triggers**:
- Push to `main` branch
- Pull Requests

**Jobs**:
1. **Test**: Runs `flutter test`
2. **Build**: Builds APK and Web artifacts (on release tags)
