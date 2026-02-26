import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'voice_guidance_service.dart';

/// Creates the native (mobile/desktop) voice guidance implementation.
VoiceGuidanceService createVoiceGuidanceService() =>
    NativeVoiceGuidanceService();

/// Native TTS implementation using flutter_tts.
/// Works on Android, iOS, macOS. Falls back gracefully on unsupported platforms.
class NativeVoiceGuidanceService implements VoiceGuidanceService {
  FlutterTts? _flutterTts;
  bool _isSpeaking = false;
  bool _available = false;
  Completer<void>? _initCompleter;

  NativeVoiceGuidanceService() {
    _initCompleter = Completer<void>();
    _doInit();
  }

  Future<void> _doInit() async {
    try {
      _flutterTts = FlutterTts();
      await _flutterTts!.setLanguage('en-US');
      await _flutterTts!.setSpeechRate(0.5);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);

      _flutterTts!.setStartHandler(() => _isSpeaking = true);
      _flutterTts!.setCompletionHandler(() => _isSpeaking = false);
      _flutterTts!.setCancelHandler(() => _isSpeaking = false);
      _flutterTts!.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
      });

      _available = true;
      debugPrint('TTS (native) initialized successfully');
    } catch (e) {
      _available = false;
      debugPrint('TTS (native) not available: $e');
    }
    _initCompleter?.complete();
  }

  Future<void> _ensureInit() async {
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      await _initCompleter!.future;
    }
  }

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> speak(String text) async {
    await _ensureInit();
    if (!_available || _flutterTts == null) {
      debugPrint('🔊 TTS (fallback print): $text');
      return;
    }
    String cleanText = text.replaceFirst(RegExp(r'^\d+\.\s*'), '');
    if (cleanText.isEmpty) return;
    debugPrint('🔊 TTS speak: "$cleanText"');
    try {
      if (_isSpeaking) {
        await _flutterTts!.stop();
        _isSpeaking = false;
      }
      _isSpeaking = true;
      await _flutterTts!.speak(cleanText);
    } catch (e) {
      _isSpeaking = false;
      debugPrint('TTS speak error: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts?.stop();
      _isSpeaking = false;
    } catch (_) {}
  }

  @override
  void dispose() {
    _flutterTts?.stop();
  }
}
