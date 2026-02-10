import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/core/services/voice_guidance_service.dart';

void main() {
  test('VoiceGuidanceServiceImpl toggles isSpeaking', () async {
    final service = VoiceGuidanceServiceImpl();

    expect(service.isSpeaking, isFalse);

    final speakFuture = service.speak('hello');
    expect(service.isSpeaking, isTrue);
    await speakFuture;

    expect(service.isSpeaking, isFalse);

    await service.stop();
    expect(service.isSpeaking, isFalse);
  });
}
