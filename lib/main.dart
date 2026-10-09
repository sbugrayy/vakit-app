// Uygulamanın giriş noktası ve bağımlılık enjeksiyonu başlatıcısı.

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vakit/app/app.dart';
import 'package:vakit/location/repository/device_location.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/notifications/repository/notification_bridge.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';
import 'package:vakit/qibla/repository/heading_source.dart';
import 'package:vakit/settings/repository/settings_store.dart';
import 'package:vakit/shared/clock.dart';
import 'package:vakit/shared/diyanet/diyanet_api.dart';
import 'package:vakit/shared/storage/shared_preferences_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr');

  final sharedPreferencesStore = SharedPreferencesStore();
  const clock = SystemClock();
  final diyanetApi = DiyanetApi();
  final locationStore = LocationStore(sharedPreferencesStore);
  final settingsStore = SettingsStore(sharedPreferencesStore);
  final prayerTimesRepository = DefaultPrayerTimesRepository(
    api: diyanetApi,
    store: sharedPreferencesStore,
    clock: clock,
  );
  final notificationBridge = NotificationBridge();
  final deviceLocation = DeviceLocation();
  final headingSource = HeadingSource();

  runApp(
    App(
      locationStore: locationStore,
      settingsStore: settingsStore,
      prayerTimesRepository: prayerTimesRepository,
      diyanetApi: diyanetApi,
      notificationBridge: notificationBridge,
      clock: clock,
      deviceLocation: deviceLocation,
      headingSource: headingSource,
    ),
  );
}
