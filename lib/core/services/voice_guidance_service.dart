import 'package:flutter_riverpod/flutter_riverpod.dart';

// Abstract Interface
/// Interface for text-to-speech voice guidance.
abstract class VoiceGuidanceService {
  /// Speaks the provided [text].
  Future<void> speak(String text);
  
  /// Stops any currently playing speech.
  Future<void> stop();
  
  /// Returns true if currently speaking.
  bool get isSpeaking;
}

// Dummy Implementation (until flutter_tts is added)
/// Implementation of [VoiceGuidanceService] (Currently a mock/dummy).
class VoiceGuidanceServiceImpl implements VoiceGuidanceService {
  bool _isSpeaking = false;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> speak(String text) async {
    _isSpeaking = true;
    print("🔊 VOICE OUTPUT: $text");
    await Future.delayed(const Duration(seconds: 2)); // Simulate speech time
    _isSpeaking = false;
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
    print("🔇 VOICE STOPPED");
  }
}

final voiceGuidanceServiceProvider = Provider<VoiceGuidanceService>((ref) {
  return VoiceGuidanceServiceImpl();
});
