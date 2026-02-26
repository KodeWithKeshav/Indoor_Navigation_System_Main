import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/core/services/voice_guidance_service.dart';

// Note: The VoiceGuidanceServiceImpl now uses flutter_tts which requires
// a platform host. These tests verify the interface and provider structure.
// Full TTS integration is verified manually on device/web.

void main() {
  test('VoiceGuidanceServiceImpl implements VoiceGuidanceService', () {
    final service = VoiceGuidanceServiceImpl();
    expect(service, isA<VoiceGuidanceService>());
    expect(service.isSpeaking, isFalse);
    service.dispose();
  });

  test('voiceGuidanceServiceProvider is defined', () {
    // Just verify the provider exists and is properly typed
    expect(voiceGuidanceServiceProvider, isNotNull);
  });
}
