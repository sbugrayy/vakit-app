// QiblaPage ve QiblaView widget testleri.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vakit/location/models/selected_location.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';
import 'package:vakit/qibla/cubit/qibla_cubit.dart';
import 'package:vakit/qibla/cubit/qibla_state.dart';
import 'package:vakit/qibla/cubit/qibla_time_cubit.dart';
import 'package:vakit/qibla/models/heading_reading.dart';
import 'package:vakit/qibla/repository/heading_source.dart';
import 'package:vakit/qibla/view/qibla_page.dart';
import 'package:vakit/shared/clock.dart';
import 'package:vakit/theme/app_colors.dart';
import 'package:vakit/theme/app_theme.dart';

import '../../helpers/fixed_clock.dart';

class _MockQiblaCubit extends MockCubit<QiblaState> implements QiblaCubit {}

class _MockQiblaTimeCubit extends MockCubit<QiblaTimeState>
    implements QiblaTimeCubit {}

class _MockLocationStore extends Mock implements LocationStore {}

class _MockHeadingSource extends Mock implements HeadingSource {}

class _MockPrayerTimesRepository extends Mock
    implements PrayerTimesRepository {}

void main() {
  const fallbackLocation = SelectedLocation(
    cityId: '0',
    cityName: 'FALLBACK',
    districtId: '0',
    districtName: 'FALLBACK',
  );

  late _MockQiblaCubit mockCubit;
  late _MockQiblaTimeCubit mockTimeCubit;

  setUpAll(() async {
    registerFallbackValue(fallbackLocation);
    await initializeDateFormatting('tr');
  });

  setUp(() {
    mockCubit = _MockQiblaCubit();
    mockTimeCubit = _MockQiblaTimeCubit();
    when(() => mockCubit.start()).thenAnswer((_) async {});
    when(() => mockTimeCubit.load()).thenAnswer((_) async {});
  });

  void configure360dp(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget buildSubject({
    required QiblaState state,
    QiblaTimeState timeState = const QiblaTimeState(),
    Brightness brightness = Brightness.light,
  }) {
    when(() => mockCubit.state).thenReturn(state);
    when(() => mockTimeCubit.state).thenReturn(timeState);
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<QiblaCubit>.value(value: mockCubit),
          BlocProvider<QiblaTimeCubit>.value(value: mockTimeCubit),
        ],
        child: const QiblaView(),
      ),
    );
  }

  group('QiblaView', () {
    testWidgets('Initial durumunda CircularProgressIndicator gösterir', (
      tester,
    ) async {
      configure360dp(tester);

      await tester.pumpWidget(buildSubject(state: const QiblaInitial()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'NeedsCoordinates: açık ve koyu temada metin ve Konumumu bul butonu '
      'görünür',
      (tester) async {
        configure360dp(tester);

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(
              state: const QiblaNeedsCoordinates(),
              brightness: brightness,
            ),
          );
          await tester.pump();

          expect(
            find.text(
              'Kıble yönü için konumunuzun koordinatı gerekiyor. '
              "Konum Seçimi'nde 'Konumumu bul'u kullanın.",
            ),
            findsOneWidget,
          );
          expect(find.text('Konumumu bul'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'NeedsCoordinates: Konumumu bul butonuna basılınca /konum açılır '
      've dönüşte start çağrılır',
      (tester) async {
        configure360dp(tester);
        when(() => mockCubit.state).thenReturn(const QiblaNeedsCoordinates());
        when(
          () => mockTimeCubit.state,
        ).thenReturn(const QiblaTimeState(loaded: true));

        final router = GoRouter(
          initialLocation: '/kible',
          routes: [
            GoRoute(
              path: '/kible',
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider<QiblaCubit>.value(value: mockCubit),
                  BlocProvider<QiblaTimeCubit>.value(value: mockTimeCubit),
                ],
                child: const QiblaView(),
              ),
            ),
            GoRoute(
              path: '/konum',
              builder: (context, state) => const Scaffold(
                body: Text('Konum Seçimi Sayfası'),
              ),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pump();

        expect(find.text('Konumumu bul'), findsOneWidget);
        await tester.tap(find.text('Konumumu bul'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Konum Seçimi Sayfası'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Unavailable: açık ve koyu temada hata mesajı görünür',
      (tester) async {
        configure360dp(tester);

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(
              state: const QiblaUnavailable('Örnek hata mesajı'),
              brightness: brightness,
            ),
          );
          await tester.pump();

          expect(find.text('Örnek hata mesajı'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Ready + okuma: 151°, Kıble açısı, hizalama metni, '
      'Kâbe uzaklığı görünür',
      (tester) async {
        configure360dp(tester);

        const readyState = QiblaReady(
          bearing: 151,
          distanceKm: 2405.1,
          reading: HeadingReading(
            heading: 151,
            accuracy: HeadingAccuracy.high,
            trueNorth: true,
          ),
          turn: 0,
          aligned: true,
        );

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(state: readyState, brightness: brightness),
          );
          await tester.pump();

          expect(find.text('151°'), findsOneWidget);
          expect(find.text('Kıble açısı'), findsOneWidget);
          expect(find.text('Kıbleye dönüksünüz'), findsOneWidget);
          expect(find.text("Kâbe'ye uzaklık 2.405 km"), findsOneWidget);
          expect(find.byType(CustomPaint), findsWidgets);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Ready + turn > 0: Telefonu sağa çevirin görünür',
      (tester) async {
        configure360dp(tester);

        const readyState = QiblaReady(
          bearing: 151.62,
          distanceKm: 2405.1,
          reading: HeadingReading(
            heading: 100,
            accuracy: HeadingAccuracy.medium,
            trueNorth: true,
          ),
          turn: 51.62,
        );

        await tester.pumpWidget(buildSubject(state: readyState));
        await tester.pump();

        expect(find.text('Telefonu sağa çevirin'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Ready + turn < 0: Telefonu sola çevirin görünür',
      (tester) async {
        configure360dp(tester);

        const readyState = QiblaReady(
          bearing: 151.62,
          distanceKm: 2405.1,
          reading: HeadingReading(
            heading: 200,
            accuracy: HeadingAccuracy.medium,
            trueNorth: true,
          ),
          turn: -48.38,
        );

        await tester.pumpWidget(buildSubject(state: readyState));
        await tester.pump();

        expect(find.text('Telefonu sola çevirin'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Ready + okuma yokken: Pusula aranıyor... görünür',
      (tester) async {
        configure360dp(tester);

        const readyState = QiblaReady(
          bearing: 151.62,
          distanceKm: 2405.1,
        );

        await tester.pumpWidget(buildSubject(state: readyState));
        await tester.pump();

        expect(find.text('Pusula aranıyor...'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'needsCalibration iken kalibrasyon kartı görünür',
      (tester) async {
        configure360dp(tester);

        const lowAccuracyState = QiblaReady(
          bearing: 151.62,
          distanceKm: 2405.1,
          reading: HeadingReading(
            heading: 151,
            accuracy: HeadingAccuracy.low,
            trueNorth: true,
          ),
          turn: 0.62,
          aligned: true,
        );

        await tester.pumpWidget(buildSubject(state: lowAccuracyState));
        await tester.pump();

        expect(
          find.text(
            'Pusula hassasiyeti düşük. '
            'Telefonu havada 8 çizerek kalibre edin.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'needsCalibration değilken kalibrasyon kartı görünmez',
      (tester) async {
        configure360dp(tester);

        const highAccuracyState = QiblaReady(
          bearing: 151.62,
          distanceKm: 2405.1,
          reading: HeadingReading(
            heading: 151,
            accuracy: HeadingAccuracy.high,
            trueNorth: true,
          ),
          turn: 0.62,
          aligned: true,
        );

        await tester.pumpWidget(buildSubject(state: highAccuracyState));
        await tester.pump();

        expect(
          find.text(
            'Pusula hassasiyeti düşük. '
            'Telefonu havada 8 çizerek kalibre edin.',
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Ready: açık ve koyu temada Kıble saati ve 11:32 görünür',
      (tester) async {
        configure360dp(tester);
        const readyState = QiblaReady(
          bearing: 151,
          distanceKm: 2405.1,
        );
        final timeState = QiblaTimeState(
          time: DateTime.utc(2026, 9, 30, 8, 32),
          utcOffset: const Duration(hours: 3),
          loaded: true,
        );

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(
              state: readyState,
              timeState: timeState,
              brightness: brightness,
            ),
          );
          await tester.pump();

          expect(find.text('Kıble saati'), findsOneWidget);
          expect(find.text('11:32'), findsOneWidget);
          expect(
            find.text(
              'Bu saatte güneş kıble yönündedir. '
              'Pusula yoksa güneşe dönerek kıbleyi bulabilirsiniz.',
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'NeedsCoordinates: açık ve koyu temada Kıble saati ve 11:32 görünür',
      (tester) async {
        configure360dp(tester);
        final timeState = QiblaTimeState(
          time: DateTime.utc(2026, 9, 30, 8, 32),
          utcOffset: const Duration(hours: 3),
          loaded: true,
        );

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(
              state: const QiblaNeedsCoordinates(),
              timeState: timeState,
              brightness: brightness,
            ),
          );
          await tester.pump();

          expect(find.text('Kıble saati'), findsOneWidget);
          expect(find.text('11:32'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Unavailable: açık ve koyu temada Kıble saati ve 11:32 görünür',
      (tester) async {
        configure360dp(tester);
        final timeState = QiblaTimeState(
          time: DateTime.utc(2026, 9, 30, 8, 32),
          utcOffset: const Duration(hours: 3),
          loaded: true,
        );

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(
              state: const QiblaUnavailable('Pusula sensörü yok'),
              timeState: timeState,
              brightness: brightness,
            ),
          );
          await tester.pump();

          expect(find.text('Kıble saati'), findsOneWidget);
          expect(find.text('11:32'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'time == null iken Kıble saati kartı gösterilmez',
      (tester) async {
        configure360dp(tester);
        const readyState = QiblaReady(
          bearing: 151,
          distanceKm: 2405.1,
        );
        const timeState = QiblaTimeState(loaded: true);

        await tester.pumpWidget(
          buildSubject(
            state: readyState,
            timeState: timeState,
          ),
        );
        await tester.pump();

        expect(find.text('Kıble saati'), findsNothing);
        expect(find.text('11:32'), findsNothing);
        expect(find.byType(Card), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'QiblaPage bağımlılık sağlayıcılarla açılır ve cubit başlatılır',
      (tester) async {
        configure360dp(tester);
        final locationStore = _MockLocationStore();
        final headingSource = _MockHeadingSource();
        final repository = _MockPrayerTimesRepository();
        final clock = FixedClock(DateTime.utc(2026, 9, 30, 9));

        when(locationStore.load).thenAnswer(
          (_) async => const SelectedLocation(
            cityId: '539',
            cityName: 'İSTANBUL',
            districtId: '9541',
            districtName: 'İSTANBUL',
            latitude: 41.0082,
            longitude: 28.9784,
          ),
        );
        when(
          () => headingSource.watch(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) => const Stream.empty());
        when(() => repository.load(any())).thenAnswer(
          (_) async => const PrayerTimesResult(
            days: [],
            source: PrayerDataSource.diyanet,
          ),
        );

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<LocationStore>.value(value: locationStore),
              RepositoryProvider<HeadingSource>.value(value: headingSource),
              RepositoryProvider<PrayerTimesRepository>.value(
                value: repository,
              ),
              RepositoryProvider<Clock>.value(value: clock),
            ],
            child: const MaterialApp(
              home: QiblaPage(),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(QiblaView), findsOneWidget);
        expect(find.text('Kıble'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    test('CompassDialPainter shouldRepaint kontrolü', () {
      final scheme1 = AppColors.light();
      final scheme2 = AppColors.dark();

      final p1 = CompassDialPainter(
        heading: 10,
        bearing: 150,
        isAligned: false,
        colorScheme: scheme1,
      );
      final pSame = CompassDialPainter(
        heading: 10,
        bearing: 150,
        isAligned: false,
        colorScheme: scheme1,
      );
      final pDiffHeading = CompassDialPainter(
        heading: 20,
        bearing: 150,
        isAligned: false,
        colorScheme: scheme1,
      );
      final pDiffBearing = CompassDialPainter(
        heading: 10,
        bearing: 160,
        isAligned: false,
        colorScheme: scheme1,
      );
      final pDiffAligned = CompassDialPainter(
        heading: 10,
        bearing: 150,
        isAligned: true,
        colorScheme: scheme1,
      );
      final pDiffScheme = CompassDialPainter(
        heading: 10,
        bearing: 150,
        isAligned: false,
        colorScheme: scheme2,
      );

      expect(p1.shouldRepaint(pSame), isFalse);
      expect(p1.shouldRepaint(pDiffHeading), isTrue);
      expect(p1.shouldRepaint(pDiffBearing), isTrue);
      expect(p1.shouldRepaint(pDiffAligned), isTrue);
      expect(p1.shouldRepaint(pDiffScheme), isTrue);
    });
  });
}
