// HomePage ve HomeView widget testleri.

import 'dart:async';
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
import 'package:vakit/notifications/repository/notification_bridge.dart';
import 'package:vakit/prayer_times/cubit/prayer_times_cubit.dart';
import 'package:vakit/prayer_times/cubit/prayer_times_state.dart';
import 'package:vakit/prayer_times/models/prayer.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';
import 'package:vakit/prayer_times/models/prayer_schedule.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';
import 'package:vakit/prayer_times/view/home_page.dart';
import 'package:vakit/shared/clock.dart';
import 'package:vakit/theme/app_theme.dart';

import '../../helpers/fixed_clock.dart';

class _MockPrayerTimesCubit extends MockCubit<PrayerTimesState>
    implements PrayerTimesCubit {}

class _MockLocationStore extends Mock implements LocationStore {}

class _MockPrayerTimesRepository extends Mock
    implements PrayerTimesRepository {}

class _MockNotificationBridge extends Mock implements NotificationBridge {}

void main() {
  const istanbul = SelectedLocation(
    cityId: '539',
    cityName: 'İSTANBUL',
    districtId: '9541',
    districtName: 'İSTANBUL',
    latitude: 41.0082,
    longitude: 28.9784,
  );

  late _MockPrayerTimesCubit mockCubit;
  late List<PrayerDay> days;
  late FixedClock clock;

  setUpAll(() async {
    await initializeDateFormatting('tr');
    final fixtureJson = File(
      'test/fixtures/diyanet/vakitler_9541.json',
    ).readAsStringSync();
    final dynamic decoded = jsonDecode(fixtureJson);
    days = PrayerDay.listFromDiyanetJson(decoded as List<dynamic>);
  });

  setUp(() {
    mockCubit = _MockPrayerTimesCubit();
    clock = FixedClock(DateTime.utc(2026, 9, 30, 7));

    when(
      () => mockCubit.requestNotificationPermission(),
    ).thenAnswer((_) async => true);
    when(
      () => mockCubit.openExactAlarmSettings(),
    ).thenAnswer((_) async {});
    when(
      () => mockCubit.refreshPermissionStatus(),
    ).thenAnswer((_) async {});
    when(
      () => mockCubit.load(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async {});
  });

  Widget buildSubject({
    required PrayerTimesState state,
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
      home: BlocProvider<PrayerTimesCubit>.value(
        value: mockCubit,
        child: HomeView(onSelectLocation: onSelectLocation),
      ),
    );
  }

  void configure360dp(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('HomeView', () {
    testWidgets(
      'Loading ve Initial durumlarında CircularProgressIndicator gösterir',
      (tester) async {
        configure360dp(tester);

        await tester.pumpWidget(
          buildSubject(state: const PrayerTimesInitial()),
        );
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          buildSubject(state: const PrayerTimesLoading()),
        );
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'NeedsLocation: açık ve koyu temada metin ve Konum seç butonu '
      'görünür, tıklanınca callback çağrılır',
      (tester) async {
        configure360dp(tester);

        for (final brightness in [Brightness.light, Brightness.dark]) {
          var onSelectLocationCalled = false;
          await tester.pumpWidget(
            buildSubject(
              state: const PrayerTimesNeedsLocation(),
              brightness: brightness,
              onSelectLocation: () async {
                onSelectLocationCalled = true;
              },
            ),
          );
          await tester.pump();

          expect(
            find.text('Vakitleri gösterebilmemiz için konumunuzu seçin.'),
            findsOneWidget,
          );
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
      've dönüşte load çağırır',
      (tester) async {
        configure360dp(tester);

        when(() => mockCubit.state).thenReturn(
          const PrayerTimesNeedsLocation(),
        );

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => BlocProvider<PrayerTimesCubit>.value(
                value: mockCubit,
                child: const HomeView(),
              ),
            ),
            GoRoute(
              path: '/konum',
              builder: (context, state) => const Scaffold(
                body: Text('Konum Seçim Sayfası'),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );
        await tester.pump();

        expect(find.text('Konum seç'), findsOneWidget);
        await tester.tap(find.text('Konum seç'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Konum Seçim Sayfası'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Failure: açık ve koyu temada mesaj ve Tekrar dene butonu görünür, '
      'tıklanınca load çağrılır',
      (tester) async {
        configure360dp(tester);

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(
              state: const PrayerTimesFailure('Örnek hata mesajı'),
              brightness: brightness,
            ),
          );
          await tester.pump();

          expect(find.text('Örnek hata mesajı'), findsOneWidget);
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
      'Loaded: açık ve koyu temada Sıradaki vakit, Öğle, 12:59, sayaç '
      've 6 vakit adı görünür',
      (tester) async {
        configure360dp(tester);

        final status = PrayerSchedule(days).statusAt(clock.now());
        final loadedState = PrayerTimesLoaded(
          location: istanbul,
          result: PrayerTimesResult(
            days: days,
            source: PrayerDataSource.diyanet,
            fetchedAt: DateTime.utc(2026, 9, 30, 7),
          ),
          status: status,
        );

        for (final brightness in [Brightness.light, Brightness.dark]) {
          var locationActionCalled = false;
          await tester.pumpWidget(
            buildSubject(
              state: loadedState,
              brightness: brightness,
              onSelectLocation: () async {
                locationActionCalled = true;
              },
            ),
          );
          await tester.pump();

          expect(find.text('Sıradaki vakit'), findsOneWidget);
          expect(find.text('Öğle'), findsAtLeastNWidgets(1));
          expect(find.text('12:59'), findsAtLeastNWidgets(1));
          expect(find.text('02:59:00'), findsOneWidget);

          expect(find.text('İmsak'), findsOneWidget);
          expect(find.text('Güneş'), findsOneWidget);
          expect(find.text('İkindi'), findsOneWidget);
          expect(find.text('Akşam'), findsOneWidget);
          expect(find.text('Yatsı'), findsOneWidget);

          expect(tester.takeException(), isNull);

          expect(find.byTooltip('Kıble'), findsOneWidget);

          await tester.tap(find.byTooltip('Yenile'));
          await tester.pump();
          verify(() => mockCubit.load(forceRefresh: true)).called(1);

          await tester.tap(find.byTooltip('Konum seç'));
          await tester.pump();
          expect(locationActionCalled, isTrue);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Loaded: Kıble eylemine tıklandığında /kible rotasına gider',
      (tester) async {
        configure360dp(tester);

        final status = PrayerSchedule(days).statusAt(clock.now());
        final loadedState = PrayerTimesLoaded(
          location: istanbul,
          result: PrayerTimesResult(
            days: days,
            source: PrayerDataSource.diyanet,
          ),
          status: status,
        );
        when(() => mockCubit.state).thenReturn(loadedState);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => BlocProvider<PrayerTimesCubit>.value(
                value: mockCubit,
                child: const HomeView(),
              ),
            ),
            GoRoute(
              path: '/kible',
              builder: (context, state) => const Scaffold(
                body: Text('Kıble Sayfası'),
              ),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pump();

        expect(find.byTooltip('Kıble'), findsOneWidget);
        await tester.tap(find.byTooltip('Kıble'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Kıble Sayfası'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Loaded: offline kaynağında Çevrimdışı hesap rozeti görünür',
      (tester) async {
        configure360dp(tester);

        final status = PrayerSchedule(days).statusAt(clock.now());
        final loadedState = PrayerTimesLoaded(
          location: istanbul,
          result: PrayerTimesResult(
            days: days,
            source: PrayerDataSource.offline,
          ),
          status: status,
        );

        await tester.pumpWidget(buildSubject(state: loadedState));
        await tester.pump();

        expect(find.text('Çevrimdışı hesap'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Loaded: cache kaynağında ve gün sayısı 3 ten az ise '
      'Veriler güncellenmeli rozeti görünür',
      (tester) async {
        configure360dp(tester);

        final status = PrayerSchedule(days.take(2).toList()).statusAt(
          clock.now(),
        );
        final loadedState = PrayerTimesLoaded(
          location: istanbul,
          result: PrayerTimesResult(
            days: days.take(2).toList(),
            source: PrayerDataSource.cache,
          ),
          status: status,
        );

        await tester.pumpWidget(buildSubject(state: loadedState));
        await tester.pump();

        expect(find.text('Veriler güncellenmeli'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Loaded: next null ise güncel değil uyarısı gösterilir',
      (tester) async {
        configure360dp(tester);

        const emptyStatus = ScheduleStatus(daysRemaining: 0);
        const loadedState = PrayerTimesLoaded(
          location: istanbul,
          result: PrayerTimesResult(
            days: [],
            source: PrayerDataSource.diyanet,
          ),
          status: emptyStatus,
        );

        await tester.pumpWidget(buildSubject(state: loadedState));
        await tester.pump();

        expect(
          find.text('Vakit bilgisi güncel değil. Yenileyin.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Loaded: hicri tarih boş ise yalnızca miladi tarih gösterilir',
      (tester) async {
        configure360dp(tester);

        final firstDay = days.first;
        final dayWithoutHijri = PrayerDay(
          date: firstDay.date,
          utcOffset: firstDay.utcOffset,
          times: firstDay.times,
          hijriDate: '',
        );

        final status = ScheduleStatus(
          today: dayWithoutHijri,
          next: PrayerMoment(
            prayer: Prayer.ogle,
            time: dayWithoutHijri.timeOf(Prayer.ogle),
            date: dayWithoutHijri.date,
          ),
          remaining: const Duration(hours: 1),
          progress: 0.5,
          daysRemaining: 1,
        );

        final loadedState = PrayerTimesLoaded(
          location: istanbul,
          result: PrayerTimesResult(
            days: [dayWithoutHijri],
            source: PrayerDataSource.diyanet,
          ),
          status: status,
        );

        await tester.pumpWidget(buildSubject(state: loadedState));
        await tester.pump();

        expect(find.textContaining('•'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Loaded: günün vakitleri sonraki güne göre geçmiş olarak işaretlenir',
      (tester) async {
        configure360dp(tester);

        final today = days.first;
        final tomorrow = days[1];

        final status = ScheduleStatus(
          today: today,
          next: PrayerMoment(
            prayer: Prayer.imsak,
            time: tomorrow.timeOf(Prayer.imsak),
            date: tomorrow.date,
          ),
          remaining: const Duration(hours: 5),
          progress: 0.8,
          daysRemaining: 29,
        );

        final loadedState = PrayerTimesLoaded(
          location: istanbul,
          result: PrayerTimesResult(
            days: days,
            source: PrayerDataSource.diyanet,
          ),
          status: status,
        );

        await tester.pumpWidget(buildSubject(state: loadedState));
        await tester.pump();

        expect(find.byType(HomeView), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Loaded: exactAlarmAllowed false iken bant ve İzin ver butonu görünür, '
      'tıklanınca openExactAlarmSettings çağrılır (açık ve koyu tema)',
      (tester) async {
        configure360dp(tester);

        final status = PrayerSchedule(days).statusAt(clock.now());
        final loadedState = PrayerTimesLoaded(
          location: istanbul,
          result: PrayerTimesResult(
            days: days,
            source: PrayerDataSource.diyanet,
          ),
          status: status,
          exactAlarmAllowed: false,
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
              "Bildirimin vakit girer girmez güncellenmesi için 'Alarmlar "
              "ve hatırlatıcılar' iznini verin.",
            ),
            findsOneWidget,
          );
          expect(find.text('İzin ver'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('İzin ver'));
          await tester.pump();
          verify(() => mockCubit.openExactAlarmSettings()).called(1);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Loaded: exactAlarmAllowed true iken bant ve İzin ver butonu '
      'gösterilmez',
      (tester) async {
        configure360dp(tester);

        final status = PrayerSchedule(days).statusAt(clock.now());
        final loadedState = PrayerTimesLoaded(
          location: istanbul,
          result: PrayerTimesResult(
            days: days,
            source: PrayerDataSource.diyanet,
          ),
          status: status,
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
              "Bildirimin vakit girer girmez güncellenmesi için 'Alarmlar "
              "ve hatırlatıcılar' iznini verin.",
            ),
            findsNothing,
          );
          expect(find.text('İzin ver'), findsNothing);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Uygulama resumed durumuna geçtiğinde refreshPermissionStatus çağrılır',
      (tester) async {
        configure360dp(tester);

        final status = PrayerSchedule(days).statusAt(clock.now());
        final loadedState = PrayerTimesLoaded(
          location: istanbul,
          result: PrayerTimesResult(
            days: days,
            source: PrayerDataSource.diyanet,
          ),
          status: status,
        );

        await tester.pumpWidget(buildSubject(state: loadedState));
        await tester.pump();

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        verify(() => mockCubit.refreshPermissionStatus()).called(1);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        await tester.pump();

        verifyNever(() => mockCubit.refreshPermissionStatus());
      },
    );

    testWidgets(
      'exactAlarmAllowed güncellendiğinde HomeView yeniden çizilir',
      (tester) async {
        configure360dp(tester);

        final controller = StreamController<PrayerTimesState>();
        addTearDown(() => unawaited(controller.close()));

        final status = PrayerSchedule(days).statusAt(clock.now());
        final stateWithBanner = PrayerTimesLoaded(
          location: istanbul,
          result: PrayerTimesResult(
            days: days,
            source: PrayerDataSource.diyanet,
          ),
          status: status,
          exactAlarmAllowed: false,
        );
        final stateWithoutBanner = stateWithBanner.copyWith(
          exactAlarmAllowed: true,
        );

        whenListen(
          mockCubit,
          controller.stream,
          initialState: stateWithBanner,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.light,
            home: BlocProvider<PrayerTimesCubit>.value(
              value: mockCubit,
              child: const HomeView(),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('İzin ver'), findsOneWidget);

        controller.add(stateWithoutBanner);
        await tester.pump();
        await tester.pump();
        expect(find.text('İzin ver'), findsNothing);
      },
    );
  });

  group('HomePage', () {
    testWidgets(
      'HomePage RepositoryProvider lardan cubiti kurar ve load çağırır',
      (tester) async {
        configure360dp(tester);

        final locationStore = _MockLocationStore();
        final repository = _MockPrayerTimesRepository();
        final notificationBridge = _MockNotificationBridge();

        when(locationStore.load).thenAnswer((_) async => null);
        when(
          notificationBridge.requestNotificationPermission,
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<LocationStore>.value(value: locationStore),
              RepositoryProvider<PrayerTimesRepository>.value(
                value: repository,
              ),
              RepositoryProvider<NotificationBridge>.value(
                value: notificationBridge,
              ),
              RepositoryProvider<Clock>.value(value: clock),
            ],
            child: const MaterialApp(
              home: HomePage(),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(HomeView), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'HomePage onSelectLocation callback ini HomeView e aktarır',
      (tester) async {
        configure360dp(tester);

        final locationStore = _MockLocationStore();
        final repository = _MockPrayerTimesRepository();
        final notificationBridge = _MockNotificationBridge();

        when(locationStore.load).thenAnswer((_) async => null);
        when(
          notificationBridge.requestNotificationPermission,
        ).thenAnswer((_) async => true);

        var onSelectLocationCalled = false;

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<LocationStore>.value(value: locationStore),
              RepositoryProvider<PrayerTimesRepository>.value(
                value: repository,
              ),
              RepositoryProvider<NotificationBridge>.value(
                value: notificationBridge,
              ),
              RepositoryProvider<Clock>.value(value: clock),
            ],
            child: MaterialApp(
              home: HomePage(
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
