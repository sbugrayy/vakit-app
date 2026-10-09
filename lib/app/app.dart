// Uygulama kök widget'ı ve bağımlılık sağlayıcı hiyerarşisi.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vakit/location/repository/device_location.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/navigation/app_router.dart';
import 'package:vakit/notifications/repository/notification_bridge.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';
import 'package:vakit/qibla/repository/heading_source.dart';
import 'package:vakit/settings/cubit/settings_cubit.dart';
import 'package:vakit/settings/models/app_settings.dart';
import 'package:vakit/settings/repository/settings_store.dart';
import 'package:vakit/shared/clock.dart';
import 'package:vakit/shared/diyanet/diyanet_api.dart';
import 'package:vakit/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({
    required this.locationStore,
    required this.settingsStore,
    required this.prayerTimesRepository,
    required this.diyanetApi,
    required this.notificationBridge,
    required this.clock,
    required this.deviceLocation,
    required this.headingSource,
    this.routerConfig,
    super.key,
  });

  final LocationStore locationStore;
  final SettingsStore settingsStore;
  final PrayerTimesRepository prayerTimesRepository;
  final DiyanetApi diyanetApi;
  final NotificationBridge notificationBridge;
  final Clock clock;
  final DeviceLocation deviceLocation;
  final HeadingSource headingSource;
  final RouterConfig<Object>? routerConfig;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocationStore>.value(value: locationStore),
        RepositoryProvider<SettingsStore>.value(value: settingsStore),
        RepositoryProvider<PrayerTimesRepository>.value(
          value: prayerTimesRepository,
        ),
        RepositoryProvider<DiyanetApi>.value(value: diyanetApi),
        RepositoryProvider<NotificationBridge>.value(
          value: notificationBridge,
        ),
        RepositoryProvider<Clock>.value(value: clock),
        RepositoryProvider<DeviceLocation>.value(value: deviceLocation),
        RepositoryProvider<HeadingSource>.value(value: headingSource),
      ],
      child: BlocProvider(
        create: (_) {
          final cubit = SettingsCubit(
            store: settingsStore,
            notificationBridge: notificationBridge,
          );
          unawaited(cubit.load());
          return cubit;
        },
        child: BlocBuilder<SettingsCubit, AppSettings>(
          buildWhen: (previous, current) =>
              previous.themePreference != current.themePreference,
          builder: (context, settings) {
            return MaterialApp.router(
              title: 'Vakit',
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: settings.themeMode,
              locale: const Locale('tr'),
              supportedLocales: const [Locale('tr')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              routerConfig: routerConfig ?? appRouter,
            );
          },
        ),
      ),
    );
  }
}
