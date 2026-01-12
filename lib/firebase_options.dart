import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: "AIzaSyD7nPodt9c7fTTE6ObtxGF21rfUw8KQk4M",
        appId: "1:298939372836:web:15ef5c2e4dc6ce61584fb1",
        messagingSenderId: "298939372836",
        projectId: "indoor-nav-system-90d8e",
        authDomain: "indoor-nav-system-90d8e.firebaseapp.com",
        storageBucket: "indoor-nav-system-90d8e.firebasestorage.app",
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnimplementedError('Run flutterfire configure');
      case TargetPlatform.iOS:
        throw UnimplementedError('Run flutterfire configure');
      case TargetPlatform.macOS:
        throw UnimplementedError('Run flutterfire configure');
      case TargetPlatform.windows:
        throw UnimplementedError('Windows is not supported');
      case TargetPlatform.linux:
        throw UnimplementedError('Linux is not supported');
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}
