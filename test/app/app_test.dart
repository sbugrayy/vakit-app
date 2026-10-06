// App widget'ı ve navigasyon entegrasyonu widget testleri.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vakit/app/app.dart';
import 'package:vakit/location/repository/device_location.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/navigation/app_router.dart';
import 'package:vakit/notifications/repository/notification_bridge.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';
import 'package:vakit/prayer_times/view/home_page.dart';
import 'package:vakit/qibla/repository/heading_source.dart';
import 'package:vakit/settings/models/app_settings.dart';
import 'package:vakit/settings/repository/settings_store.dart';
import 'package:vakit/shared/clock.dart';
import 'package:vakit/shared/diyanet/diyanet_api.dart';

class _MockLocationStore extends Mock implements LocationStore {}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockPrayerTimesRepository extends Mock
    implements PrayerTimesRepository {}

class _MockDiyanetApi extends Mock implements DiyanetApi {}

class _MockNotificationBridge extends Mock implements NotificationBridge {}

class _MockClock extends Mock implements Clock {}

class _MockDeviceLocation extends Mock implements DeviceLocation {}

class _MockHeadingSource extends Mock implements HeadingSource {}

void main() {
  late _MockLocationStore locationStore;
  late _MockSettingsStore settingsStore;
  late _MockPrayerTimesRepository prayerTimesRepository;
  late _MockDiyanetApi diyanetApi;
  late _MockNotificationBridge notificationBridge;
  late _MockClock clock;
  late _MockDeviceLocation deviceLocation;
  late _MockHeadingSource headingSource;

  setUpAll(() async {
    await initializeDateFormatting('tr');
  });

  setUp(() {
    locationStore = _MockLocationStore();
    settingsStore = _MockSettingsStore();
    prayerTimesRepository = _MockPrayerTimesRepository();
    diyanetApi = _MockDiyanetApi();
    notificationBridge = _MockNotificationBridge();
    clock = _MockClock();
    deviceLocation = _MockDeviceLocation();
    headingSource = _MockHeadingSource();

    when(() => locationStore.load()).thenAnswer((_) async => null);
    when(() => settingsStore.load()).thenAnswer(
      (_) async => const AppSettings(),
    );
    when(
      () => notificationBridge.requestNotificationPermission(),
    ).thenAnswer((_) async => true);
  });

  Widget buildTestApp({RouterConfig<Object>? routerConfig}) {
    return App(
      locationStore: locationStore,
      settingsStore: settingsStore,
      prayerTimesRepository: prayerTimesRepository,
      diyanetApi: diyanetApi,
      notificationBridge: notificationBridge,
      clock: clock,
      deviceLocation: deviceLocation,
      headingSource: headingSource,
      routerConfig: routerConfig,
    );
  }

  group('App', () {
    testWidgets(
      'MaterialApp tr yereli, bağımlılıklar ve ana sayfa ile başlar',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestApp());
        await tester.pump();

        expect(find.byType(HomePage), findsOneWidget);

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.title, equals('Vakit'));
        expect(materialApp.locale, equals(const Locale('tr')));
        expect(materialApp.supportedLocales, contains(const Locale('tr')));
        expect(materialApp.themeMode, equals(ThemeMode.system));

        final element = tester.element(find.byType(HomePage));
        expect(element.read<LocationStore>(), equals(locationStore));
        expect(element.read<SettingsStore>(), equals(settingsStore));
        expect(
          element.read<PrayerTimesRepository>(),
          equals(prayerTimesRepository),
        );
        expect(element.read<DiyanetApi>(), equals(diyanetApi));
        expect(
          element.read<NotificationBridge>(),
          equals(notificationBridge),
        );
        expect(element.read<Clock>(), equals(clock));
        expect(element.read<DeviceLocation>(), equals(deviceLocation));
        expect(element.read<HeadingSource>(), equals(headingSource));
      },
    );

    testWidgets(
      'ThemeMode.system açık ve koyu platformBrightness modlarında çökmüyor',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        await tester.pumpWidget(buildTestApp());
        await tester.pump();
        expect(find.byType(HomePage), findsOneWidget);

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpWidget(buildTestApp());
        await tester.pump();
        expect(find.byType(HomePage), findsOneWidget);
      },
    );

    testWidgets(
      'kayıtlı tercih dark iken MaterialApp.themeMode == ThemeMode.dark',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        when(() => settingsStore.load()).thenAnswer(
          (_) async => const AppSettings(
            themePreference: ThemePreference.dark,
          ),
        );

        await tester.pumpWidget(buildTestApp());
        await tester.pump();

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.themeMode, equals(ThemeMode.dark));
      },
    );

    testWidgets(
      'HomePage doğrudan kök rotada gösterilir',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestApp());
        await tester.pump();

        expect(find.byType(HomePage), findsOneWidget);
      },
    );

    test('createAppRouter kök rotasını ve başlangıç konumunu ayarlar', () {
      final router = createAppRouter();
      expect(router.configuration.routes.length, equals(3));
      final routes = router.configuration.routes.cast<GoRoute>().toList();
      expect(routes[0].path, equals('/'));
      expect(routes[1].path, equals('/konum'));
      expect(routes[2].path, equals('/kible'));
      expect(
        router.routeInformationProvider.value.uri.path,
        equals('/'),
      );
    });
  });
}
