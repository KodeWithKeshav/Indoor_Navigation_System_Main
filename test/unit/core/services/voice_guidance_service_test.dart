import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/core/services/voice_guidance_service.dart';

// Note: The VoiceGuidanceService now uses platform-conditional imports
// (flutter_tts on native, SpeechSynthesis on web).
// These tests verify the interface and provider structure.
// Full TTS integration is verified manually on device/web.

void main() {
  test('voiceGuidanceServiceProvider is defined', () {
    // Just verify the provider exists and is properly typed
    expect(voiceGuidanceServiceProvider, isNotNull);
  });
}
