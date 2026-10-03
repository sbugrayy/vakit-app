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
import 'package:vakit/qibla/cubit/qibla_cubit.dart';
import 'package:vakit/qibla/cubit/qibla_state.dart';
import 'package:vakit/qibla/models/heading_reading.dart';
import 'package:vakit/qibla/repository/heading_source.dart';
import 'package:vakit/qibla/view/qibla_page.dart';
import 'package:vakit/theme/app_colors.dart';
import 'package:vakit/theme/app_theme.dart';

class _MockQiblaCubit extends MockCubit<QiblaState> implements QiblaCubit {}

class _MockLocationStore extends Mock implements LocationStore {}

class _MockHeadingSource extends Mock implements HeadingSource {}

void main() {
  late _MockQiblaCubit mockCubit;

  setUpAll(() async {
    await initializeDateFormatting('tr');
  });

  setUp(() {
    mockCubit = _MockQiblaCubit();
    when(() => mockCubit.start()).thenAnswer((_) async {});
  });

  void configure360dp(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget buildSubject({
    required QiblaState state,
    Brightness brightness = Brightness.light,
  }) {
    when(() => mockCubit.state).thenReturn(state);
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: BlocProvider<QiblaCubit>.value(
        value: mockCubit,
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

        final router = GoRouter(
          initialLocation: '/kible',
          routes: [
            GoRoute(
              path: '/kible',
              builder: (context, state) => BlocProvider<QiblaCubit>.value(
                value: mockCubit,
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
      'QiblaPage bağımlılık sağlayıcılarla açılır ve cubit başlatılır',
      (tester) async {
        configure360dp(tester);
        final locationStore = _MockLocationStore();
        final headingSource = _MockHeadingSource();

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

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<LocationStore>.value(value: locationStore),
              RepositoryProvider<HeadingSource>.value(value: headingSource),
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
