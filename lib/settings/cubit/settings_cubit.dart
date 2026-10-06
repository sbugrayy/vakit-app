// Tema ve bildirim tercihlerini yöneten durum yöneticisi.

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vakit/notifications/repository/notification_bridge.dart';
import 'package:vakit/settings/models/app_settings.dart';
import 'package:vakit/settings/repository/settings_store.dart';

class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit({
    required this._store,
    required this._notificationBridge,
  }) : super(const AppSettings());

  final SettingsStore _store;
  final NotificationBridge _notificationBridge;

  Future<void> load() async {
    final settings = await _store.load();
    if (isClosed) {
      return;
    }
    emit(settings);
  }

  Future<void> setThemePreference(ThemePreference value) async {
    final updated = state.copyWith(themePreference: value);
    await _store.save(updated);
    if (isClosed) {
      return;
    }
    emit(updated);
  }

  Future<void> setNotificationEnabled({required bool enabled}) async {
    final updated = state.copyWith(notificationEnabled: enabled);
    await _store.save(updated);
    if (isClosed) {
      return;
    }
    emit(updated);

    try {
      await _notificationBridge.setEnabled(enabled: enabled);
    } on PlatformException {
      // Platform köprü hatası yutulur; tercih yine kaydedilmiş kalır.
    }
  }
}
