// MonthlyPage ve MonthlyView widget testleri.

import 'dart:convert';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vakit/location/models/selected_location.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/prayer_times/cubit/monthly_times_cubit.dart';
import 'package:vakit/prayer_times/cubit/monthly_times_state.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';
import 'package:vakit/prayer_times/view/monthly_page.dart';
import 'package:vakit/shared/clock.dart';
import 'package:vakit/theme/app_theme.dart';

import '../../helpers/fixed_clock.dart';

class _MockMonthlyTimesCubit extends MockCubit<MonthlyTimesState>
    implements MonthlyTimesCubit {}

class _MockLocationStore extends Mock implements LocationStore {}

class _MockPrayerTimesRepository extends Mock
    implements PrayerTimesRepository {}

void main() {
  const istanbul = SelectedLocation(
    cityId: '539',
    cityName: 'İSTANBUL',
    districtId: '9541',
    districtName: 'İSTANBUL',
    latitude: 41.0082,
    longitude: 28.9784,
  );

  late _MockMonthlyTimesCubit mockCubit;
  late List<PrayerDay> days;

  setUpAll(() async {
    await initializeDateFormatting('tr');
    final fixtureJson = File(
      'test/fixtures/diyanet/vakitler_9541.json',
    ).readAsStringSync();
    final dynamic decoded = jsonDecode(fixtureJson);
    days = PrayerDay.listFromDiyanetJson(decoded as List<dynamic>);
  });

  setUp(() {
    mockCubit = _MockMonthlyTimesCubit();
    when(() => mockCubit.load()).thenAnswer((_) async {});
  });

  void configure360dp(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget buildSubject({
    required MonthlyTimesState state,
    Brightness brightness = Brightness.light,
    Future<void> Function()? onSelectLocation,
  }) {
    when(() => mockCubit.state).thenReturn(state);
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: BlocProvider<MonthlyTimesCubit>.value(
        value: mockCubit,
        child: MonthlyView(onSelectLocation: onSelectLocation),
      ),
    );
  }

  group('MonthlyView', () {
    testWidgets(
      'Loading durumunda CircularProgressIndicator gösterir (açık ve koyu)',
      (tester) async {
        configure360dp(tester);

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(
              state: const MonthlyTimesLoading(),
              brightness: brightness,
            ),
          );
          await tester.pump();

          expect(find.text('Aylık Vakitler'), findsOneWidget);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'NeedsLocation: metin ve Konum seç butonu görünür, dokununca '
      'callback çağrılır (açık ve koyu)',
      (tester) async {
        configure360dp(tester);

        for (final brightness in [Brightness.light, Brightness.dark]) {
          var onSelectLocationCalled = false;
          await tester.pumpWidget(
            buildSubject(
              state: const MonthlyTimesNeedsLocation(),
              brightness: brightness,
              onSelectLocation: () async {
                onSelectLocationCalled = true;
              },
            ),
          );
          await tester.pump();

          expect(find.text('Önce konum seçin.'), findsOneWidget);
          expect(find.text('Konum seç'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Konum seç'));
          await tester.pump();
          expect(onSelectLocationCalled, isTrue);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'NeedsLocation: callback verilmediğinde /konum rotasına gider '
      've dönüşte load çağrılır',
      (tester) async {
        configure360dp(tester);

        when(() => mockCubit.state).thenReturn(
          const MonthlyTimesNeedsLocation(),
        );

        final router = GoRouter(
          initialLocation: '/aylik',
          routes: [
            GoRoute(
              path: '/aylik',
              builder: (context, state) =>
                  BlocProvider<MonthlyTimesCubit>.value(
                    value: mockCubit,
                    child: const MonthlyView(),
                  ),
            ),
            GoRoute(
              path: '/konum',
              builder: (context, state) => const Scaffold(
                body: Text('Konum Seçim Ekranı'),
              ),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pump();

        expect(find.text('Konum seç'), findsOneWidget);
        await tester.tap(find.text('Konum seç'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Konum Seçim Ekranı'), findsOneWidget);

        router.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verify(() => mockCubit.load()).called(1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Error: mesaj ve Tekrar dene butonu görünür, dokununca load çağrılır '
      '(açık ve koyu)',
      (tester) async {
        configure360dp(tester);

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(
              state: const MonthlyTimesError('Vakitler yüklenemedi.'),
              brightness: brightness,
            ),
          );
          await tester.pump();

          expect(find.text('Vakitler yüklenemedi.'), findsOneWidget);
          expect(find.text('Tekrar dene'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Tekrar dene'));
          await tester.pump();
          verify(() => mockCubit.load()).called(1);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Loaded (Diyanet): ilk kartta Bugün etiketi, doğru saatler ve '
      'ilçe/il başlığı görünür (açık ve koyu, 360 dp taşma yok)',
      (tester) async {
        configure360dp(tester);

        final loadedState = MonthlyTimesLoaded(
          location: istanbul,
          days: days,
          todayIndex: 0,
          source: PrayerDataSource.diyanet,
        );

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(
              state: loadedState,
              brightness: brightness,
            ),
          );
          await tester.pump();

          expect(find.text('Aylık Vakitler'), findsOneWidget);
          expect(find.text('İSTANBUL, İSTANBUL'), findsOneWidget);

          // İlk kartta Bugün etiketi ve ilk günün tarihi
          expect(find.text('Bugün'), findsOneWidget);
          expect(find.text('30 Eylül Çarşamba'), findsOneWidget);
          expect(find.text('19 Rebiulahir 1448'), findsOneWidget);

          // İlk günün vakit saatleri
          expect(find.text('05:28'), findsOneWidget);
          expect(find.text('06:52'), findsOneWidget);
          expect(find.text('12:59'), findsAtLeastNWidgets(1));
          expect(find.text('16:18'), findsOneWidget);
          expect(find.text('18:56'), findsOneWidget);
          expect(find.text('20:15'), findsOneWidget);

          // Vakit isimleri
          expect(find.text('İmsak'), findsAtLeastNWidgets(1));
          expect(find.text('Güneş'), findsAtLeastNWidgets(1));
          expect(find.text('Öğle'), findsAtLeastNWidgets(1));
          expect(find.text('İkindi'), findsAtLeastNWidgets(1));
          expect(find.text('Akşam'), findsAtLeastNWidgets(1));
          expect(find.text('Yatsı'), findsAtLeastNWidgets(1));

          // Çevrimdışı notu Diyanet kaynağında olmamalı
          expect(find.textContaining('Çevrimdışı hesap'), findsNothing);

          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Loaded (Offline): listenin üstünde çevrimdışı notu gösterilir '
      '(açık ve koyu, 360 dp)',
      (tester) async {
        configure360dp(tester);

        final loadedState = MonthlyTimesLoaded(
          location: istanbul,
          days: days,
          todayIndex: 0,
          source: PrayerDataSource.offline,
        );

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(
              state: loadedState,
              brightness: brightness,
            ),
          );
          await tester.pump();

          expect(
            find.text(
              'Çevrimdışı hesap: Diyanet verisine ulaşılamadı, '
              'vakitler cihazda hesaplandı.',
            ),
            findsOneWidget,
          );
          expect(find.text('Bugün'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Loaded: todayIndex == -1 olduğunda hiçbir kartta Bugün etiketi '
      'gösterilmez',
      (tester) async {
        configure360dp(tester);

        final loadedState = MonthlyTimesLoaded(
          location: istanbul,
          days: days,
          todayIndex: -1,
          source: PrayerDataSource.diyanet,
        );

        await tester.pumpWidget(buildSubject(state: loadedState));
        await tester.pump();

        expect(find.text('Bugün'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Loaded: hijriDate boş olduğunda çökmez',
      (tester) async {
        configure360dp(tester);

        final firstDay = days.first;
        final dayWithoutHijri = PrayerDay(
          date: firstDay.date,
          utcOffset: firstDay.utcOffset,
          times: firstDay.times,
          hijriDate: '',
        );

        final loadedState = MonthlyTimesLoaded(
          location: istanbul,
          days: [dayWithoutHijri],
          todayIndex: 0,
          source: PrayerDataSource.diyanet,
        );

        await tester.pumpWidget(buildSubject(state: loadedState));
        await tester.pump();

        expect(find.text('Bugün'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('MonthlyPage', () {
    testWidgets(
      'MonthlyPage bağımlılıkları context ten okur ve MonthlyView i kurar',
      (tester) async {
        configure360dp(tester);

        final locationStore = _MockLocationStore();
        final repository = _MockPrayerTimesRepository();
        final clock = FixedClock(DateTime.utc(2026, 9, 30, 9));

        when(locationStore.load).thenAnswer((_) async => null);

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<LocationStore>.value(value: locationStore),
              RepositoryProvider<PrayerTimesRepository>.value(
                value: repository,
              ),
              RepositoryProvider<Clock>.value(value: clock),
            ],
            child: const MaterialApp(
              home: MonthlyPage(),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(MonthlyPage), findsOneWidget);
        expect(find.byType(MonthlyView), findsOneWidget);
        expect(find.text('Önce konum seçin.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'MonthlyPage onSelectLocation callback ini MonthlyView e aktarır',
      (tester) async {
        configure360dp(tester);

        final locationStore = _MockLocationStore();
        final repository = _MockPrayerTimesRepository();
        final clock = FixedClock(DateTime.utc(2026, 9, 30, 9));

        when(locationStore.load).thenAnswer((_) async => null);

        var onSelectLocationCalled = false;

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<LocationStore>.value(value: locationStore),
              RepositoryProvider<PrayerTimesRepository>.value(
                value: repository,
              ),
              RepositoryProvider<Clock>.value(value: clock),
            ],
            child: MaterialApp(
              home: MonthlyPage(
                onSelectLocation: () async {
                  onSelectLocationCalled = true;
                },
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Konum seç'), findsOneWidget);
        await tester.tap(find.text('Konum seç'));
        await tester.pump();

        expect(onSelectLocationCalled, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
