// App widget'ı ve navigasyon entegrasyonu widget testleri.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vakit/app/app.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/navigation/app_router.dart';
import 'package:vakit/notifications/repository/notification_bridge.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';
import 'package:vakit/shared/clock.dart';
import 'package:vakit/shared/diyanet/diyanet_api.dart';

class _MockLocationStore extends Mock implements LocationStore {}

class _MockPrayerTimesRepository extends Mock
    implements PrayerTimesRepository {}

class _MockDiyanetApi extends Mock implements DiyanetApi {}

class _MockNotificationBridge extends Mock implements NotificationBridge {}

class _MockClock extends Mock implements Clock {}

void main() {
  late _MockLocationStore locationStore;
  late _MockPrayerTimesRepository prayerTimesRepository;
  late _MockDiyanetApi diyanetApi;
  late _MockNotificationBridge notificationBridge;
  late _MockClock clock;

  setUpAll(() async {
    await initializeDateFormatting('tr');
  });

  setUp(() {
    locationStore = _MockLocationStore();
    prayerTimesRepository = _MockPrayerTimesRepository();
    diyanetApi = _MockDiyanetApi();
    notificationBridge = _MockNotificationBridge();
    clock = _MockClock();
  });

  Widget buildTestApp({RouterConfig<Object>? routerConfig}) {
    return App(
      locationStore: locationStore,
      prayerTimesRepository: prayerTimesRepository,
      diyanetApi: diyanetApi,
      notificationBridge: notificationBridge,
      clock: clock,
      routerConfig: routerConfig,
    );
  }

  group('App', () {
    testWidgets(
      'MaterialApp tr yereli, bağımlılıklar ve yer tutucu sayfa ile başlar',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestApp());
        await tester.pump();

        expect(find.text('Vakit'), findsOneWidget);

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.title, equals('Vakit'));
        expect(materialApp.locale, equals(const Locale('tr')));
        expect(materialApp.supportedLocales, contains(const Locale('tr')));
        expect(materialApp.themeMode, equals(ThemeMode.system));

        final element = tester.element(find.text('Vakit'));
        expect(element.read<LocationStore>(), equals(locationStore));
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
        expect(find.text('Vakit'), findsOneWidget);

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpWidget(buildTestApp());
        await tester.pump();
        expect(find.text('Vakit'), findsOneWidget);
      },
    );

    testWidgets(
      'HomePlaceholderPage doğrudan pump edildiğinde Vakit metnini gösterir',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomePlaceholderPage(),
          ),
        );

        expect(find.byType(HomePlaceholderPage), findsOneWidget);
        expect(find.text('Vakit'), findsOneWidget);
      },
    );

    test('createAppRouter kök rotasını ve başlangıç konumunu ayarlar', () {
      final router = createAppRouter();
      expect(router.configuration.routes.length, equals(1));
      final route = router.configuration.routes.first as GoRoute;
      expect(route.path, equals('/'));
    });
  });
}
