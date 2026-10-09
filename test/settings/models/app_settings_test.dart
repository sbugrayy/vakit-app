// AppSettings modeli birim testleri.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/settings/models/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('varsayılan değerler beklendiği gibidir', () {
      const settings = AppSettings();

      expect(settings.themePreference, equals(ThemePreference.system));
      expect(settings.notificationEnabled, isTrue);
      expect(settings.themeMode, equals(ThemeMode.system));
    });

    test('themeMode ThemePreference değerlerine doğru eşlenir', () {
      const system = AppSettings();
      const light = AppSettings(themePreference: ThemePreference.light);
      const dark = AppSettings(themePreference: ThemePreference.dark);

      expect(system.themeMode, equals(ThemeMode.system));
      expect(light.themeMode, equals(ThemeMode.light));
      expect(dark.themeMode, equals(ThemeMode.dark));
    });

    test('copyWith alanları doğru günceller', () {
      const initial = AppSettings();

      final updatedTheme = initial.copyWith(
        themePreference: ThemePreference.dark,
      );
      expect(updatedTheme.themePreference, equals(ThemePreference.dark));
      expect(updatedTheme.notificationEnabled, isTrue);

      final updatedNotification = initial.copyWith(
        notificationEnabled: false,
      );
      expect(
        updatedNotification.themePreference,
        equals(ThemePreference.system),
      );
      expect(updatedNotification.notificationEnabled, isFalse);

      final unchanged = initial.copyWith();
      expect(unchanged, equals(initial));
    });

    test('eşitlik ve props doğru çalışır', () {
      const settingsA = AppSettings(
        themePreference: ThemePreference.light,
        notificationEnabled: false,
      );
      const settingsB = AppSettings(
        themePreference: ThemePreference.light,
        notificationEnabled: false,
      );
      const settingsC = AppSettings(
        themePreference: ThemePreference.dark,
        notificationEnabled: false,
      );

      expect(settingsA, equals(settingsB));
      expect(settingsA.hashCode, equals(settingsB.hashCode));
      expect(settingsA, isNot(equals(settingsC)));
      expect(
        settingsA.props,
        equals([ThemePreference.light, false]),
      );
    });
  });
}
