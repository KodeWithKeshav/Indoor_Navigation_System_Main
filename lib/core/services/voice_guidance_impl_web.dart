// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'voice_guidance_service.dart';

/// Creates the web-specific voice guidance implementation.
VoiceGuidanceService createVoiceGuidanceService() => WebVoiceGuidanceService();

/// Web TTS implementation using direct JavaScript interop.
/// Uses dart:js to call the browser's native SpeechSynthesis API directly,
/// bypassing the incomplete dart:html SpeechSynthesis wrapper.
class WebVoiceGuidanceService implements VoiceGuidanceService {
  bool _isSpeaking = false;

  // Hold a reference to the JS utterance object to prevent garbage collection.
  js.JsObject? _currentUtterance;

  @override
  bool get isSpeaking => _isSpeaking;

  /// Get the speechSynthesis object from the browser window.
  js.JsObject? get _synth {
    try {
      return js.context['speechSynthesis'] as js.JsObject?;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> speak(String text) async {
    // Strip step numbers for cleaner speech
    String cleanText = text.replaceFirst(RegExp(r'^\d+\.\s*'), '');
    if (cleanText.isEmpty) return;

    debugPrint('🔊 TTS (web) speak: "$cleanText"');

    final synth = _synth;
    if (synth == null) {
      debugPrint('TTS (web) error: speechSynthesis API not available');
      return;
    }

    try {
      // Cancel any ongoing speech only if needed
      synth.callMethod('cancel');

      // Create the utterance via JS constructor
      final utterance = js.JsObject(js.context['SpeechSynthesisUtterance'], [
        cleanText,
      ]);
      utterance['rate'] = 0.9;
      utterance['volume'] = 1.0;

      // Keep strong reference to prevent GC
      _currentUtterance = utterance;

      utterance['onstart'] = js.allowInterop((_) {
        _isSpeaking = true;
        debugPrint('TTS (web) started speaking');
      });

      utterance['onend'] = js.allowInterop((_) {
        _isSpeaking = false;
        _currentUtterance = null;
        debugPrint('TTS (web) finished speaking');
      });

      utterance['onerror'] = js.allowInterop((event) {
        _isSpeaking = false;
        _currentUtterance = null;
        String errorMsg = 'unknown';
        try {
          final jsEvent = event as js.JsObject;
          errorMsg = jsEvent['error']?.toString() ?? 'unknown';
        } catch (_) {}
        debugPrint('TTS (web) error: $errorMsg');
      });

      _isSpeaking = true;
      synth.callMethod('speak', [utterance]);
    } catch (e) {
      _isSpeaking = false;
      _currentUtterance = null;
      debugPrint('TTS (web) speak error: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      _synth?.callMethod('cancel');
      _isSpeaking = false;
      _currentUtterance = null;
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      _synth?.callMethod('cancel');
      _currentUtterance = null;
    } catch (_) {}
  }
}
