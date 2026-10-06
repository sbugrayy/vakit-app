// Uygulama genelindeki kullanıcı tercihlerini temsil eden ayarlar modeli.

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ThemePreference { system, light, dark }

class AppSettings extends Equatable {
  const AppSettings({
    this.themePreference = ThemePreference.system,
    this.notificationEnabled = true,
  });

  final ThemePreference themePreference;
  final bool notificationEnabled;

  ThemeMode get themeMode => switch (themePreference) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };

  AppSettings copyWith({
    ThemePreference? themePreference,
    bool? notificationEnabled,
  }) {
    return AppSettings(
      themePreference: themePreference ?? this.themePreference,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }

  @override
  List<Object?> get props => [themePreference, notificationEnabled];
}
