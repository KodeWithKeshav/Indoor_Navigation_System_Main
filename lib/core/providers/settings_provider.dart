import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final bool isHighContrast;
  final double textScaleFactor;
  final bool isVoiceEnabled;

  SettingsState({
    this.isHighContrast = false,
    this.textScaleFactor = 1.0,
    this.isVoiceEnabled = true,
  });

  SettingsState copyWith({
    bool? isHighContrast,
    double? textScaleFactor,
    bool? isVoiceEnabled,
  }) {
    return SettingsState(
      isHighContrast: isHighContrast ?? this.isHighContrast,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      isVoiceEnabled: isVoiceEnabled ?? this.isVoiceEnabled,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    return SettingsState();
  }

  void toggleHighContrast(bool value) {
    state = state.copyWith(isHighContrast: value);
  }

  void setTextScale(double scale) {
    state = state.copyWith(textScaleFactor: scale);
  }

  void toggleVoice(bool value) {
    state = state.copyWith(isVoiceEnabled: value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
