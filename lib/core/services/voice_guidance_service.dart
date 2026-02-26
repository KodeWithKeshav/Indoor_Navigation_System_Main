import 'package:flutter_riverpod/flutter_riverpod.dart';

// Conditional import: picks the web implementation when dart:html is available,
// otherwise uses the native (flutter_tts) implementation.
import 'voice_guidance_impl.dart'
    if (dart.library.html) 'voice_guidance_impl_web.dart' as impl;

/// Interface for text-to-speech voice guidance.
abstract class VoiceGuidanceService {
  /// Speaks the provided [text].
  Future<void> speak(String text);

  /// Stops any currently playing speech.
  Future<void> stop();

  /// Returns true if currently speaking.
  bool get isSpeaking;

  /// Dispose resources.
  void dispose();
}

final voiceGuidanceServiceProvider = Provider<VoiceGuidanceService>((ref) {
  final service = impl.createVoiceGuidanceService();
  ref.onDispose(() => service.dispose());
  return service;
});
