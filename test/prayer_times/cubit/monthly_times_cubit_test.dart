// MonthlyTimesCubit için durum geçişleri ve hata birim testleri.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vakit/location/models/selected_location.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/prayer_times/cubit/monthly_times_cubit.dart';
import 'package:vakit/prayer_times/cubit/monthly_times_state.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';

import '../../helpers/fixed_clock.dart';

class _MockLocationStore extends Mock implements LocationStore {}

class _MockPrayerTimesRepository extends Mock
    implements PrayerTimesRepository {}

void main() {
  const fallbackLocation = SelectedLocation(
    cityId: '0',
    cityName: 'FALLBACK',
    districtId: '0',
    districtName: 'FALLBACK',
  );

  const istanbul = SelectedLocation(
    cityId: '539',
    cityName: 'İSTANBUL',
    districtId: '9541',
    districtName: 'İSTANBUL',
    latitude: 41.0082,
    longitude: 28.9784,
  );

  late _MockLocationStore locationStore;
  late _MockPrayerTimesRepository repository;
  late List<PrayerDay> fixtureDays;

  setUpAll(() {
    registerFallbackValue(fallbackLocation);
    final fixtureJson = File(
      'test/fixtures/diyanet/vakitler_9541.json',
    ).readAsStringSync();
    final dynamic decoded = jsonDecode(fixtureJson);
    fixtureDays = PrayerDay.listFromDiyanetJson(decoded as List<dynamic>);
  });

  setUp(() {
    locationStore = _MockLocationStore();
    repository = _MockPrayerTimesRepository();
  });

  group('MonthlyTimesCubit', () {
    test('başlangıç durumu MonthlyTimesLoading dir', () {
      final cubit = MonthlyTimesCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      );
      addTearDown(cubit.close);

      expect(cubit.state, equals(const MonthlyTimesLoading()));
    });

    blocTest<MonthlyTimesCubit, MonthlyTimesState>(
      'konum yoksa MonthlyTimesNeedsLocation yayar',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => null);
      },
      build: () => MonthlyTimesCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const MonthlyTimesNeedsLocation(),
      ],
    );

    blocTest<MonthlyTimesCubit, MonthlyTimesState>(
      'başarı: 30.09.2026 öğlen, liste 30.09 dan başlar, '
      'todayIndex 0, geçmiş gün yok',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
        final pastDay = PrayerDay(
          date: DateTime.utc(2026, 9, 29),
          utcOffset: const Duration(hours: 3),
          times: fixtureDays.first.times,
          hijriDate: '18 Rebiulahir 1448',
        );
        when(() => repository.load(any())).thenAnswer(
          (_) async => PrayerTimesResult(
            days: [pastDay, ...fixtureDays],
            source: PrayerDataSource.diyanet,
          ),
        );
      },
      build: () => MonthlyTimesCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        MonthlyTimesLoaded(
          location: istanbul,
          days: fixtureDays,
          todayIndex: 0,
          source: PrayerDataSource.diyanet,
        ),
      ],
    );

    blocTest<MonthlyTimesCubit, MonthlyTimesState>(
      'depo PrayerTimesException fırlatınca MonthlyTimesError yayar',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
        when(() => repository.load(any())).thenThrow(
          const PrayerTimesException('Ağ bağlantısı yok'),
        );
      },
      build: () => MonthlyTimesCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const MonthlyTimesError('Vakitler yüklenemedi.'),
      ],
    );

    blocTest<MonthlyTimesCubit, MonthlyTimesState>(
      'genel Exception fırlatılınca MonthlyTimesError yayar',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
        when(() => repository.load(any())).thenThrow(
          Exception('Beklenmeyen hata'),
        );
      },
      build: () => MonthlyTimesCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const MonthlyTimesError('Vakitler yüklenemedi.'),
      ],
    );

    blocTest<MonthlyTimesCubit, MonthlyTimesState>(
      'hata durumundayken load önce loading sonra sonucu yayar',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
        when(() => repository.load(any())).thenAnswer(
          (_) async => PrayerTimesResult(
            days: fixtureDays,
            source: PrayerDataSource.diyanet,
          ),
        );
      },
      build: () => MonthlyTimesCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      ),
      seed: () => const MonthlyTimesError('Vakitler yüklenemedi.'),
      act: (cubit) => cubit.load(),
      expect: () => [
        const MonthlyTimesLoading(),
        MonthlyTimesLoaded(
          location: istanbul,
          days: fixtureDays,
          todayIndex: 0,
          source: PrayerDataSource.diyanet,
        ),
      ],
    );

    blocTest<MonthlyTimesCubit, MonthlyTimesState>(
      'bugün verinin dışındaysa (2027) bütün günler ve todayIndex -1',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
        when(() => repository.load(any())).thenAnswer(
          (_) async => PrayerTimesResult(
            days: fixtureDays,
            source: PrayerDataSource.diyanet,
          ),
        );
      },
      build: () => MonthlyTimesCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2027, 1, 1, 12)),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        MonthlyTimesLoaded(
          location: istanbul,
          days: fixtureDays,
          todayIndex: -1,
          source: PrayerDataSource.diyanet,
        ),
      ],
    );

    test('konum yüklenirken cubit kapanırsa durum yaymaz', () async {
      final completer = Completer<SelectedLocation?>();
      when(() => locationStore.load()).thenAnswer((_) => completer.future);

      final cubit = MonthlyTimesCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      );

      final future = cubit.load();
      await cubit.close();
      completer.complete(istanbul);
      await future;

      expect(cubit.state, equals(const MonthlyTimesLoading()));
    });

    test('vakitler yüklenirken cubit kapanırsa durum yaymaz', () async {
      final completer = Completer<PrayerTimesResult>();
      when(() => locationStore.load()).thenAnswer((_) async => istanbul);
      when(() => repository.load(any())).thenAnswer((_) => completer.future);

      final cubit = MonthlyTimesCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      );

      final future = cubit.load();
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      completer.complete(
        PrayerTimesResult(
          days: fixtureDays,
          source: PrayerDataSource.diyanet,
        ),
      );
      await future;

      expect(cubit.state, equals(const MonthlyTimesLoading()));
    });

    test('hata anında cubit kapalıysa emit çağrılmaz', () async {
      final completer = Completer<PrayerTimesResult>();
      when(() => locationStore.load()).thenAnswer((_) async => istanbul);
      when(() => repository.load(any())).thenAnswer((_) => completer.future);

      final cubit = MonthlyTimesCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      );

      final future = cubit.load();
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      completer.completeError(Exception('Hata'));
      await future;

      expect(cubit.state, equals(const MonthlyTimesLoading()));
    });
  });
}
