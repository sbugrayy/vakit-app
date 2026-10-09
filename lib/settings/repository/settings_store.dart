// Uygulama ayarlarını kalıcı depolayan ve okuyan depo sınıfı.

import 'package:vakit/settings/models/app_settings.dart';
import 'package:vakit/shared/storage/key_value_store.dart';

class SettingsStore {
  const SettingsStore(this._store);

  static const String themeKey = 'settings_theme';
  static const String notificationEnabledKey = 'settings_notification_enabled';

  final KeyValueStore _store;

  Future<AppSettings> load() async {
    final themeRaw = await _store.getString(themeKey);
    final theme = switch (themeRaw) {
      'light' => ThemePreference.light,
      'dark' => ThemePreference.dark,
      _ => ThemePreference.system,
    };

    final notificationRaw = await _store.getString(notificationEnabledKey);
    final notificationEnabled = switch (notificationRaw) {
      'false' => false,
      _ => true,
    };

    return AppSettings(
      themePreference: theme,
      notificationEnabled: notificationEnabled,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _store.setString(themeKey, settings.themePreference.name);
    await _store.setString(
      notificationEnabledKey,
      settings.notificationEnabled ? 'true' : 'false',
    );
  }
}
