import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_navigation_system/core/theme/app_theme.dart';

void main() {
  test('AppTheme defines light and dark themes', () {
    expect(AppTheme.lightTheme, isA<ThemeData>());
    expect(AppTheme.darkTheme, isA<ThemeData>());
    expect(AppTheme.highContrastTheme, isA<ThemeData>());

    expect(AppTheme.lightTheme.colorScheme.brightness, Brightness.light);
    expect(AppTheme.darkTheme.colorScheme.brightness, Brightness.dark);
  });
}
