// PrayerTimesCubit birim testleri.

import 'dart:convert';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

import '../../helpers/fixed_clock.dart';

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

  const testTick = Duration(milliseconds: 10);

  late _MockLocationStore locationStore;
  late _MockPrayerTimesRepository repository;
  late _MockNotificationBridge notificationBridge;
  late FixedClock clock;
  late List<PrayerDay> days;
  late PrayerTimesResult prayerTimesResult;

  setUpAll(() {
    final fixtureJson = File(
      'test/fixtures/diyanet/vakitler_9541.json',
    ).readAsStringSync();
    final dynamic decoded = jsonDecode(fixtureJson);
    days = PrayerDay.listFromDiyanetJson(decoded as List<dynamic>);
  });

  setUp(() {
    locationStore = _MockLocationStore();
    repository = _MockPrayerTimesRepository();
    notificationBridge = _MockNotificationBridge();
    clock = FixedClock(DateTime.utc(2026, 9, 30, 7));
    prayerTimesResult = PrayerTimesResult(
      days: days,
      source: PrayerDataSource.diyanet,
      fetchedAt: DateTime.utc(2026, 9, 30, 7),
    );
  });

  group('PrayerTimesState', () {
    test('durum sınıfları doğru props listelerini döndürür', () {
      expect(const PrayerTimesInitial().props, isEmpty);
      expect(const PrayerTimesLoading().props, isEmpty);
      expect(const PrayerTimesNeedsLocation().props, isEmpty);
      expect(
        const PrayerTimesFailure('hata').props,
        equals(['hata']),
      );

      final status = PrayerSchedule(days).statusAt(clock.now());
      final loaded = PrayerTimesLoaded(
        location: istanbul,
        result: prayerTimesResult,
        status: status,
      );
      expect(
        loaded.props,
        equals([istanbul, prayerTimesResult, status]),
      );
    });

    test('PrayerTimesLoaded copyWith alanları doğru günceller', () {
      final status = PrayerSchedule(days).statusAt(clock.now());
      final loaded = PrayerTimesLoaded(
        location: istanbul,
        result: prayerTimesResult,
        status: status,
      );

      final unchanged = loaded.copyWith();
      expect(unchanged, equals(loaded));

      final advancedStatus = PrayerSchedule(days).statusAt(
        clock.now().add(const Duration(minutes: 5)),
      );
      final updated = loaded.copyWith(status: advancedStatus);
      expect(updated.status, equals(advancedStatus));
      expect(updated.location, equals(istanbul));
      expect(updated.result, equals(prayerTimesResult));

      const ankara = SelectedLocation(
        cityId: '501',
        cityName: 'ANKARA',
        districtId: '9158',
        districtName: 'ANKARA',
      );
      final withLocation = loaded.copyWith(location: ankara);
      expect(withLocation.location, equals(ankara));

      const newResult = PrayerTimesResult(
        days: [],
        source: PrayerDataSource.offline,
      );
      final withResult = loaded.copyWith(result: newResult);
      expect(withResult.result, equals(newResult));
    });
  });

  group('PrayerTimesCubit', () {
    blocTest<PrayerTimesCubit, PrayerTimesState>(
      'konum yok ise [Loading, NeedsLocation] yayınlar ve repository '
      'çağrılmaz',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => null);
      },
      build: () => PrayerTimesCubit(
        locationStore: locationStore,
        repository: repository,
        notificationBridge: notificationBridge,
        clock: clock,
        tick: testTick,
      ),
      act: (cubit) => cubit.load(),
      expect: () => const [
        PrayerTimesLoading(),
        PrayerTimesNeedsLocation(),
      ],
      verify: (_) {
        verifyZeroInteractions(repository);
      },
    );

    blocTest<PrayerTimesCubit, PrayerTimesState>(
      'başarılı yüklemede [Loading, Loaded] yayınlar, status.next Öğle olur '
      've sync bir kez çağrılır',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
        when(
          () => repository.load(istanbul),
        ).thenAnswer((_) async => prayerTimesResult);
        when(
          () => notificationBridge.sync(
            locationLabel: any(named: 'locationLabel'),
            days: any(named: 'days'),
            enabled: any(named: 'enabled'),
          ),
        ).thenAnswer((_) async {});
      },
      build: () => PrayerTimesCubit(
        locationStore: locationStore,
        repository: repository,
        notificationBridge: notificationBridge,
        clock: clock,
        tick: testTick,
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const PrayerTimesLoading(),
        isA<PrayerTimesLoaded>()
            .having((s) => s.location, 'location', istanbul)
            .having((s) => s.result, 'result', prayerTimesResult)
            .having(
              (s) => s.status.next?.prayer,
              'next prayer',
              Prayer.ogle,
            ),
      ],
      verify: (_) {
        verify(
          () => notificationBridge.sync(
            locationLabel: 'İSTANBUL',
            days: days,
            enabled: true,
          ),
        ).called(1);
      },
    );

    blocTest<PrayerTimesCubit, PrayerTimesState>(
      'sync PlatformException atsa bile Loaded durumuna geçer',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
        when(
          () => repository.load(istanbul),
        ).thenAnswer((_) async => prayerTimesResult);
        when(
          () => notificationBridge.sync(
            locationLabel: any(named: 'locationLabel'),
            days: any(named: 'days'),
            enabled: any(named: 'enabled'),
          ),
        ).thenThrow(PlatformException(code: 'UNAVAILABLE'));
      },
      build: () => PrayerTimesCubit(
        locationStore: locationStore,
        repository: repository,
        notificationBridge: notificationBridge,
        clock: clock,
        tick: testTick,
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const PrayerTimesLoading(),
        isA<PrayerTimesLoaded>(),
      ],
    );

    blocTest<PrayerTimesCubit, PrayerTimesState>(
      'PrayerTimesException durumunda [Loading, Failure] yayınlar',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
        when(
          () => repository.load(istanbul),
        ).thenThrow(const PrayerTimesException('Ağ hatası'));
      },
      build: () => PrayerTimesCubit(
        locationStore: locationStore,
        repository: repository,
        notificationBridge: notificationBridge,
        clock: clock,
        tick: testTick,
      ),
      act: (cubit) => cubit.load(),
      expect: () => const [
        PrayerTimesLoading(),
        PrayerTimesFailure(
          'Vakitler alınamadı. İnternet bağlantınızı kontrol edip '
          'tekrar deneyin.',
        ),
      ],
    );

    blocTest<PrayerTimesCubit, PrayerTimesState>(
      'forceRefresh: true parametresi repository.load çağrısına iletilir',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
        when(
          () => repository.load(istanbul, forceRefresh: true),
        ).thenAnswer((_) async => prayerTimesResult);
        when(
          () => notificationBridge.sync(
            locationLabel: any(named: 'locationLabel'),
            days: any(named: 'days'),
            enabled: any(named: 'enabled'),
          ),
        ).thenAnswer((_) async {});
      },
      build: () => PrayerTimesCubit(
        locationStore: locationStore,
        repository: repository,
        notificationBridge: notificationBridge,
        clock: clock,
        tick: testTick,
      ),
      act: (cubit) => cubit.load(forceRefresh: true),
      verify: (_) {
        verify(
          () => repository.load(istanbul, forceRefresh: true),
        ).called(1);
      },
    );

    blocTest<PrayerTimesCubit, PrayerTimesState>(
      'tik: FixedClock 1 dk ilerletilip wait: ile beklenince '
      'remaining azalmış yeni Loaded gelir',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
        when(
          () => repository.load(istanbul),
        ).thenAnswer((_) async => prayerTimesResult);
        when(
          () => notificationBridge.sync(
            locationLabel: any(named: 'locationLabel'),
            days: any(named: 'days'),
            enabled: any(named: 'enabled'),
          ),
        ).thenAnswer((_) async {});
      },
      build: () => PrayerTimesCubit(
        locationStore: locationStore,
        repository: repository,
        notificationBridge: notificationBridge,
        clock: clock,
        tick: const Duration(milliseconds: 10),
      ),
      act: (cubit) async {
        await cubit.load();
        clock.advance(const Duration(minutes: 1));
      },
      wait: const Duration(milliseconds: 15),
      expect: () => [
        const PrayerTimesLoading(),
        isA<PrayerTimesLoaded>().having(
          (s) => s.status.remaining,
          'ilk remaining',
          const Duration(hours: 2, minutes: 59),
        ),
        isA<PrayerTimesLoaded>().having(
          (s) => s.status.remaining,
          'azalmış remaining',
          const Duration(hours: 2, minutes: 58),
        ),
      ],
    );

    test(
      'close() çağrısı sonrası timer iptal edilir ve yeni durum yayınlanmaz',
      () async {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
        when(
          () => repository.load(istanbul),
        ).thenAnswer((_) async => prayerTimesResult);
        when(
          () => notificationBridge.sync(
            locationLabel: any(named: 'locationLabel'),
            days: any(named: 'days'),
            enabled: any(named: 'enabled'),
          ),
        ).thenAnswer((_) async {});

        final cubit = PrayerTimesCubit(
          locationStore: locationStore,
          repository: repository,
          notificationBridge: notificationBridge,
          clock: clock,
          tick: const Duration(milliseconds: 10),
        );

        await cubit.load();
        expect(cubit.state, isA<PrayerTimesLoaded>());

        await cubit.close();
        expect(cubit.isClosed, isTrue);

        final statesAfterClose = <PrayerTimesState>[];
        cubit.stream.listen(statesAfterClose.add);

        clock.advance(const Duration(minutes: 10));
        await Future<void>.delayed(const Duration(milliseconds: 25));

        expect(statesAfterClose, isEmpty);
      },
    );

    test(
      'requestNotificationPermission çağrısını '
      'NotificationBridge üzerine iletir',
      () async {
        when(
          () => notificationBridge.requestNotificationPermission(),
        ).thenAnswer((_) async => true);

        final cubit = PrayerTimesCubit(
          locationStore: locationStore,
          repository: repository,
          notificationBridge: notificationBridge,
          clock: clock,
        );

        final result = await cubit.requestNotificationPermission();

        expect(result, isTrue);
        verify(
          () => notificationBridge.requestNotificationPermission(),
        ).called(1);

        await cubit.close();
      },
    );
  });
}
