import 'dart:js_interop';

import 'package:flutter/foundation.dart';

import 'voice_guidance_service.dart';

/// Creates the web-specific voice guidance implementation.
VoiceGuidanceService createVoiceGuidanceService() => WebVoiceGuidanceService();

// ---------------------------------------------------------------------------
// JS interop bindings (dart:js_interop — replaces deprecated dart:js)
// ---------------------------------------------------------------------------

@JS('SpeechSynthesisUtterance')
extension type SpeechSynthesisUtterance._(JSObject _) implements JSObject {
  external factory SpeechSynthesisUtterance(String text);
  external set rate(double value);
  external set volume(double value);
  external set onstart(JSFunction? fn);
  external set onend(JSFunction? fn);
  external set onerror(JSFunction? fn);
}

extension type SpeechSynthesisAPI._(JSObject _) implements JSObject {
  external void cancel();
  external void speak(SpeechSynthesisUtterance utterance);
}

@JS('speechSynthesis')
external SpeechSynthesisAPI get _speechSynthesisJS;

// ---------------------------------------------------------------------------

/// Web TTS implementation using dart:js_interop and the browser's native
/// SpeechSynthesis API.
class WebVoiceGuidanceService implements VoiceGuidanceService {
  bool _isSpeaking = false;

  @override
  bool get isSpeaking => _isSpeaking;

  SpeechSynthesisAPI? get _synth {
    try {
      return _speechSynthesisJS;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> speak(String text) async {
    // Strip step numbers for cleaner speech.
    final cleanText = text.replaceFirst(RegExp(r'^\d+\.\s*'), '');
    if (cleanText.isEmpty) return;

    debugPrint('🔊 TTS (web) speak: "$cleanText"');

    final synth = _synth;
    if (synth == null) {
      debugPrint('TTS (web) error: speechSynthesis API not available');
      return;
    }

    try {
      synth.cancel();

      final utterance = SpeechSynthesisUtterance(cleanText);
      utterance.rate = 0.9;
      utterance.volume = 1.0;

      utterance.onstart = (JSAny? _) {
        _isSpeaking = true;
        debugPrint('TTS (web) started speaking');
      }.toJS;

      utterance.onend = (JSAny? _) {
        _isSpeaking = false;
        debugPrint('TTS (web) finished speaking');
      }.toJS;

      utterance.onerror = (JSAny? _) {
        _isSpeaking = false;
        debugPrint('TTS (web) onerror fired');
      }.toJS;

      _isSpeaking = true;
      synth.speak(utterance);
    } catch (e) {
      _isSpeaking = false;
      debugPrint('TTS (web) speak error: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      _synth?.cancel();
      _isSpeaking = false;
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      _synth?.cancel();
    } catch (_) {}
  }
}
