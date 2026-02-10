import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indoor_navigation_system/core/providers/settings_provider.dart';

void main() {
  test('SettingsNotifier updates state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(settingsProvider).isHighContrast, isFalse);

    container.read(settingsProvider.notifier).toggleHighContrast(true);
    expect(container.read(settingsProvider).isHighContrast, isTrue);

    container.read(settingsProvider.notifier).setTextScale(1.2);
    expect(container.read(settingsProvider).textScaleFactor, 1.2);

    container.read(settingsProvider.notifier).toggleVoice(false);
    expect(container.read(settingsProvider).isVoiceEnabled, isFalse);
  });
}
