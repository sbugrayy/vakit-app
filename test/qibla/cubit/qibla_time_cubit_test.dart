// QiblaTimeCubit birim ve durum geçişi testleri.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vakit/location/models/selected_location.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';
import 'package:vakit/prayer_times/widgets/time_format.dart';
import 'package:vakit/qibla/cubit/qibla_time_cubit.dart';

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

  group('QiblaTimeCubit', () {
    test('başlangıç durumu const QiblaTimeState() dir', () {
      final cubit = QiblaTimeCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      );
      addTearDown(cubit.close);

      expect(cubit.state, equals(const QiblaTimeState()));
      expect(cubit.state.loaded, isFalse);
      expect(cubit.state.time, isNull);
      expect(cubit.state.utcOffset, isNull);
    });

    blocTest<QiblaTimeCubit, QiblaTimeState>(
      'başarı: 30.09.2026 öğlen kıble saati ve utc ofseti yayar, '
      'formatClock 11:32 verir',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
        when(() => repository.load(any())).thenAnswer(
          (_) async => PrayerTimesResult(
            days: fixtureDays,
            source: PrayerDataSource.diyanet,
          ),
        );
      },
      build: () => QiblaTimeCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        QiblaTimeState(
          time: fixtureDays.first.qiblaTime,
          utcOffset: fixtureDays.first.utcOffset,
          loaded: true,
        ),
      ],
      verify: (cubit) {
        final state = cubit.state;
        expect(formatClock(state.time!, state.utcOffset!), equals('11:32'));
      },
    );

    blocTest<QiblaTimeCubit, QiblaTimeState>(
      'konum yoksa loaded: true ve time: null yayar',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => null);
      },
      build: () => QiblaTimeCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const QiblaTimeState(loaded: true),
      ],
    );

    blocTest<QiblaTimeCubit, QiblaTimeState>(
      'konum deposu Exception fırlatırsa loaded: true ve time: null yayar',
      setUp: () {
        when(() => locationStore.load()).thenThrow(
          Exception('Konum deposu hatası'),
        );
      },
      build: () => QiblaTimeCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const QiblaTimeState(loaded: true),
      ],
    );

    blocTest<QiblaTimeCubit, QiblaTimeState>(
      'namaz vakitleri deposu Exception fırlatırsa loaded: true ve time: null '
      'yayar',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
        when(() => repository.load(any())).thenThrow(
          const PrayerTimesException('Ağ bağlantısı yok'),
        );
      },
      build: () => QiblaTimeCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const QiblaTimeState(loaded: true),
      ],
    );

    blocTest<QiblaTimeCubit, QiblaTimeState>(
      'genel Exception fırlatılırsa loaded: true ve time: null yayar',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
        when(() => repository.load(any())).thenThrow(
          Exception('Beklenmeyen hata'),
        );
      },
      build: () => QiblaTimeCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const QiblaTimeState(loaded: true),
      ],
    );

    blocTest<QiblaTimeCubit, QiblaTimeState>(
      'bugün takvimde bulunamazsa loaded: true ve time: null yayar',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
        when(() => repository.load(any())).thenAnswer(
          (_) async => PrayerTimesResult(
            days: fixtureDays,
            source: PrayerDataSource.diyanet,
          ),
        );
      },
      build: () => QiblaTimeCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2027, 1, 1, 12)),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const QiblaTimeState(loaded: true),
      ],
    );

    blocTest<QiblaTimeCubit, QiblaTimeState>(
      'günün qiblaTime değeri null ise loaded: true ve time: null yayar',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
        final dayWithoutQibla = PrayerDay(
          date: DateTime.utc(2026, 9, 30),
          utcOffset: const Duration(hours: 3),
          times: fixtureDays.first.times,
          hijriDate: fixtureDays.first.hijriDate,
        );
        when(() => repository.load(any())).thenAnswer(
          (_) async => PrayerTimesResult(
            days: [dayWithoutQibla],
            source: PrayerDataSource.diyanet,
          ),
        );
      },
      build: () => QiblaTimeCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const QiblaTimeState(loaded: true),
      ],
    );

    test('konum yüklenirken cubit kapatılırsa durum yaymaz', () async {
      final completer = Completer<SelectedLocation?>();
      when(() => locationStore.load()).thenAnswer((_) => completer.future);

      final cubit = QiblaTimeCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      );

      final future = cubit.load();
      await cubit.close();
      completer.complete(istanbul);
      await future;

      expect(cubit.state, equals(const QiblaTimeState()));
    });

    test('vakitler yüklenirken cubit kapatılırsa durum yaymaz', () async {
      final completer = Completer<PrayerTimesResult>();
      when(() => locationStore.load()).thenAnswer((_) async => istanbul);
      when(() => repository.load(any())).thenAnswer((_) => completer.future);

      final cubit = QiblaTimeCubit(
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

      expect(cubit.state, equals(const QiblaTimeState()));
    });

    test('hata anında cubit kapalıysa emit çağrılmaz', () async {
      final completer = Completer<PrayerTimesResult>();
      when(() => locationStore.load()).thenAnswer((_) async => istanbul);
      when(() => repository.load(any())).thenAnswer((_) => completer.future);

      final cubit = QiblaTimeCubit(
        locationStore: locationStore,
        repository: repository,
        clock: FixedClock(DateTime.utc(2026, 9, 30, 9)),
      );

      final future = cubit.load();
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      completer.completeError(Exception('Hata'));
      await future;

      expect(cubit.state, equals(const QiblaTimeState()));
    });
  });
}
