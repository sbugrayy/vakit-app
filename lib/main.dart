// Uygulamanın giriş noktası ve bağımlılık enjeksiyonu başlatıcısı.

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vakit/app/app.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/notifications/repository/notification_bridge.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';
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
  final prayerTimesRepository = DefaultPrayerTimesRepository(
    api: diyanetApi,
    store: sharedPreferencesStore,
    clock: clock,
  );
  final notificationBridge = NotificationBridge();

  runApp(
    App(
      locationStore: locationStore,
      prayerTimesRepository: prayerTimesRepository,
      diyanetApi: diyanetApi,
      notificationBridge: notificationBridge,
      clock: clock,
    ),
  );
}
