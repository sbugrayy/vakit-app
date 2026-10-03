// Uygulama kök widget'ı ve bağımlılık sağlayıcı hiyerarşisi.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vakit/location/repository/device_location.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/navigation/app_router.dart';
import 'package:vakit/notifications/repository/notification_bridge.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';
import 'package:vakit/shared/clock.dart';
import 'package:vakit/shared/diyanet/diyanet_api.dart';
import 'package:vakit/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({
    required this.locationStore,
    required this.prayerTimesRepository,
    required this.diyanetApi,
    required this.notificationBridge,
    required this.clock,
    required this.deviceLocation,
    this.routerConfig,
    super.key,
  });

  final LocationStore locationStore;
  final PrayerTimesRepository prayerTimesRepository;
  final DiyanetApi diyanetApi;
  final NotificationBridge notificationBridge;
  final Clock clock;
  final DeviceLocation deviceLocation;
  final RouterConfig<Object>? routerConfig;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocationStore>.value(value: locationStore),
        RepositoryProvider<PrayerTimesRepository>.value(
          value: prayerTimesRepository,
        ),
        RepositoryProvider<DiyanetApi>.value(value: diyanetApi),
        RepositoryProvider<NotificationBridge>.value(
          value: notificationBridge,
        ),
        RepositoryProvider<Clock>.value(value: clock),
        RepositoryProvider<DeviceLocation>.value(value: deviceLocation),
      ],
      child: MaterialApp.router(
        title: 'Vakit',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: const Locale('tr'),
        supportedLocales: const [Locale('tr')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: routerConfig ?? appRouter,
      ),
    );
  }
}
