// DefaultPrayerTimesRepository ve PrayerTimesResult sınıfı birim testleri.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vakit/location/models/selected_location.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';
import 'package:vakit/shared/diyanet/diyanet_api.dart';
import 'package:vakit/shared/diyanet/diyanet_api_exception.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/in_memory_store.dart';

class _MockDiyanetApi extends Mock implements DiyanetApi {}

void main() {
  const istanbulWithCoordinates = SelectedLocation(
    cityId: '539',
    cityName: 'İSTANBUL',
    districtId: '9541',
    districtName: 'İSTANBUL',
    latitude: 41.0082,
    longitude: 28.9784,
  );

  const istanbulWithoutCoordinates = SelectedLocation(
    cityId: '539',
    cityName: 'İSTANBUL',
    districtId: '9541',
    districtName: 'İSTANBUL',
  );

  late String fixtureJson;

  setUpAll(() {
    fixtureJson = File(
      'test/fixtures/diyanet/vakitler_9541.json',
    ).readAsStringSync();
  });

  group('PrayerTimesResult ve PrayerTimesException modelleri', () {
    test('PrayerTimesResult props listesini doğru oluşturur', () {
      final days = PrayerDay.listFromDiyanetJson(
        [
          {
            'MiladiTarihKisa': '01.10.2026',
            'GreenwichOrtalamaZamani': 3.0,
            'HicriTarihUzun': '20 Rebiulahir 1448',
            'Imsak': '05:29',
            'Gunes': '06:53',
            'Ogle': '12:59',
            'Ikindi': '16:16',
            'Aksam': '18:55',
            'Yatsi': '20:14',
          },
        ],
      );
      final fetchedAt = DateTime.utc(2026, 10, 1, 7);
      final result1 = PrayerTimesResult(
        days: days,
        source: PrayerDataSource.diyanet,
        fetchedAt: fetchedAt,
      );
      final result2 = PrayerTimesResult(
        days: days,
        source: PrayerDataSource.diyanet,
        fetchedAt: fetchedAt,
      );

      expect(result1, equals(result2));
      expect(
        result1.props,
        equals([days, PrayerDataSource.diyanet, fetchedAt]),
      );
    });

    test('PrayerTimesException toString mesajı formatlar', () {
      const exception = PrayerTimesException('Bağlantı hatası');
      expect(
        exception.toString(),
        equals('PrayerTimesException: Bağlantı hatası'),
      );
      expect(exception.message, equals('Bağlantı hatası'));
    });
  });

  group('DefaultPrayerTimesRepository senaryoları', () {
    test(
      'Senaryo 1: İlk açılışta çevrimiçi Diyanet verisini çeker ve kaydeder',
      () async {
        final clock = FixedClock(DateTime.parse('2026-10-01T07:00:00Z'));
        final store = InMemoryStore();
        final api = _MockDiyanetApi();

        when(
          () => api.fetchPrayerDaysJson('9541'),
        ).thenAnswer((_) async => fixtureJson);

        final repository = DefaultPrayerTimesRepository(
          api: api,
          store: store,
          clock: clock,
        );

        final result = await repository.load(istanbulWithCoordinates);

        expect(result.source, equals(PrayerDataSource.diyanet));
        expect(result.days.length, equals(32));
        expect(
          result.fetchedAt,
          equals(DateTime.parse('2026-10-01T07:00:00Z')),
        );
        expect(
          await store.getString('prayer_days_9541'),
          equals(fixtureJson),
        );
        expect(
          await store.getString('prayer_days_9541_fetched_at'),
          equals('2026-10-01T07:00:00.000Z'),
        );
        verify(() => api.fetchPrayerDaysJson('9541')).called(1);
      },
    );

    test(
      'Senaryo 2: Önbellek taze olduğunda API çağrılmadan önbellekten döner',
      () async {
        final clock = FixedClock(DateTime.parse('2026-10-01T07:00:00Z'));
        final store = InMemoryStore();
        final api = _MockDiyanetApi();

        when(
          () => api.fetchPrayerDaysJson('9541'),
        ).thenAnswer((_) async => fixtureJson);

        final repository = DefaultPrayerTimesRepository(
          api: api,
          store: store,
          clock: clock,
        );

        final firstResult = await repository.load(istanbulWithCoordinates);
        expect(firstResult.source, equals(PrayerDataSource.diyanet));

        final secondResult = await repository.load(istanbulWithCoordinates);
        expect(secondResult.source, equals(PrayerDataSource.cache));
        expect(secondResult.days.length, equals(32));
        expect(
          secondResult.fetchedAt,
          equals(DateTime.parse('2026-10-01T07:00:00Z')),
        );

        verify(() => api.fetchPrayerDaysJson(any())).called(1);
      },
    );

    test(
      'Senaryo 3: Önbellekte 10 günden az kaldığında API yenilemesi yapar',
      () async {
        final clock = FixedClock(DateTime.parse('2026-10-25T07:00:00Z'));
        final store = InMemoryStore({
          'prayer_days_9541': fixtureJson,
          'prayer_days_9541_fetched_at': '2026-10-01T07:00:00.000Z',
        });
        final api = _MockDiyanetApi();

        when(
          () => api.fetchPrayerDaysJson('9541'),
        ).thenAnswer((_) async => fixtureJson);

        final repository = DefaultPrayerTimesRepository(
          api: api,
          store: store,
          clock: clock,
        );

        final result = await repository.load(istanbulWithCoordinates);

        expect(result.source, equals(PrayerDataSource.diyanet));
        expect(
          result.fetchedAt,
          equals(DateTime.parse('2026-10-25T07:00:00Z')),
        );
        expect(
          await store.getString('prayer_days_9541_fetched_at'),
          equals('2026-10-25T07:00:00.000Z'),
        );
        verify(() => api.fetchPrayerDaysJson('9541')).called(1);
      },
    );

    test(
      'Senaryo 4: forceRefresh true iken taze önbelleğe rağmen API çağrılır',
      () async {
        final clock = FixedClock(DateTime.parse('2026-10-01T07:00:00Z'));
        final store = InMemoryStore({
          'prayer_days_9541': fixtureJson,
          'prayer_days_9541_fetched_at': '2026-10-01T06:00:00.000Z',
        });
        final api = _MockDiyanetApi();

        when(
          () => api.fetchPrayerDaysJson('9541'),
        ).thenAnswer((_) async => fixtureJson);

        final repository = DefaultPrayerTimesRepository(
          api: api,
          store: store,
          clock: clock,
        );

        final result = await repository.load(
          istanbulWithCoordinates,
          forceRefresh: true,
        );

        expect(result.source, equals(PrayerDataSource.diyanet));
        expect(
          result.fetchedAt,
          equals(DateTime.parse('2026-10-01T07:00:00Z')),
        );
        verify(() => api.fetchPrayerDaysJson('9541')).called(1);
      },
    );

    test(
      'Senaryo 5: API hata verdiğinde önbellekte gün varsa önbellek döner',
      () async {
        final clock = FixedClock(DateTime.parse('2026-10-25T07:00:00Z'));
        final store = InMemoryStore({
          'prayer_days_9541': fixtureJson,
          'prayer_days_9541_fetched_at': '2026-10-01T07:00:00.000Z',
        });
        final api = _MockDiyanetApi();

        when(
          () => api.fetchPrayerDaysJson('9541'),
        ).thenThrow(
          const DiyanetApiException(
            kind: DiyanetApiErrorKind.network,
            message: 'Ağ hatası',
          ),
        );

        final repository = DefaultPrayerTimesRepository(
          api: api,
          store: store,
          clock: clock,
        );

        final result = await repository.load(istanbulWithCoordinates);

        expect(result.source, equals(PrayerDataSource.cache));
        expect(result.days.length, equals(32));
        expect(
          result.fetchedAt,
          equals(DateTime.parse('2026-10-01T07:00:00Z')),
        );
        verify(() => api.fetchPrayerDaysJson('9541')).called(1);
      },
    );

    test(
      'Senaryo 6: API hata, önbellek yok ve koordinat varsa offline döner',
      () async {
        final clock = FixedClock(DateTime.parse('2026-10-01T07:00:00Z'));
        final store = InMemoryStore();
        final api = _MockDiyanetApi();

        when(
          () => api.fetchPrayerDaysJson('9541'),
        ).thenThrow(
          const DiyanetApiException(
            kind: DiyanetApiErrorKind.network,
            message: 'Ağ hatası',
          ),
        );

        final repository = DefaultPrayerTimesRepository(
          api: api,
          store: store,
          clock: clock,
        );

        final result = await repository.load(istanbulWithCoordinates);

        expect(result.source, equals(PrayerDataSource.offline));
        expect(result.days.length, equals(30));
        expect(result.days.first.date, equals(DateTime.utc(2026, 10)));
        expect(result.fetchedAt, isNull);
        verify(() => api.fetchPrayerDaysJson('9541')).called(1);
      },
    );

    test(
      'Senaryo 7: UTC ve Türkiye günü farklıyken çevrimdışı ilk gün '
      'Türkiye günüdür',
      () async {
        final clock = FixedClock(DateTime.parse('2026-09-30T22:30:00Z'));
        final store = InMemoryStore();
        final api = _MockDiyanetApi();

        when(
          () => api.fetchPrayerDaysJson('9541'),
        ).thenThrow(
          const DiyanetApiException(
            kind: DiyanetApiErrorKind.network,
            message: 'Ağ hatası',
          ),
        );

        final repository = DefaultPrayerTimesRepository(
          api: api,
          store: store,
          clock: clock,
        );

        final result = await repository.load(istanbulWithCoordinates);

        expect(result.source, equals(PrayerDataSource.offline));
        expect(result.days.first.date, equals(DateTime.utc(2026, 10)));
      },
    );

    test(
      'Senaryo 8: API hata, önbellek yok ve koordinat yoksa hata fırlatır',
      () async {
        final clock = FixedClock(DateTime.parse('2026-10-01T07:00:00Z'));
        final store = InMemoryStore();
        final api = _MockDiyanetApi();

        when(
          () => api.fetchPrayerDaysJson('9541'),
        ).thenThrow(
          const DiyanetApiException(
            kind: DiyanetApiErrorKind.network,
            message: 'Ağ hatası',
          ),
        );

        final repository = DefaultPrayerTimesRepository(
          api: api,
          store: store,
          clock: clock,
        );

        expect(
          () => repository.load(istanbulWithoutCoordinates),
          throwsA(
            isA<PrayerTimesException>().having(
              (e) => e.message,
              'message',
              equals('Vakitler alınamadı: internet bağlantısı gerekiyor'),
            ),
          ),
        );
      },
    );

    test(
      'Senaryo 9: Önbellek bozuk olduğunda yok sayılır, API verisi kaydedilir',
      () async {
        final clock = FixedClock(DateTime.parse('2026-10-01T07:00:00Z'));
        final store = InMemoryStore({
          'prayer_days_9541': '{bozuk',
          'prayer_days_9541_fetched_at': '2026-10-01T07:00:00.000Z',
        });
        final api = _MockDiyanetApi();

        when(
          () => api.fetchPrayerDaysJson('9541'),
        ).thenAnswer((_) async => fixtureJson);

        final repository = DefaultPrayerTimesRepository(
          api: api,
          store: store,
          clock: clock,
        );

        final result = await repository.load(istanbulWithCoordinates);

        expect(result.source, equals(PrayerDataSource.diyanet));
        expect(
          await store.getString('prayer_days_9541'),
          equals(fixtureJson),
        );
      },
    );

    test(
      'Senaryo 10a: Önbellek süresi dolmuş ve API hata verdiğinde koordinat '
      'varsa çevrimdışı hesap döner',
      () async {
        final clock = FixedClock(DateTime.parse('2026-11-05T07:00:00Z'));
        final store = InMemoryStore({
          'prayer_days_9541': fixtureJson,
          'prayer_days_9541_fetched_at': '2026-10-01T07:00:00.000Z',
        });
        final api = _MockDiyanetApi();

        when(
          () => api.fetchPrayerDaysJson('9541'),
        ).thenThrow(
          const DiyanetApiException(
            kind: DiyanetApiErrorKind.network,
            message: 'Ağ hatası',
          ),
        );

        final repository = DefaultPrayerTimesRepository(
          api: api,
          store: store,
          clock: clock,
        );

        final result = await repository.load(istanbulWithCoordinates);

        expect(result.source, equals(PrayerDataSource.offline));
        expect(result.days.length, equals(30));
        expect(result.days.first.date, equals(DateTime.utc(2026, 11, 5)));
      },
    );

    test(
      'Senaryo 10b: Önbellek süresi dolmuş ve API hata verdiğinde koordinat '
      'yoksa PrayerTimesException fırlatır',
      () async {
        final clock = FixedClock(DateTime.parse('2026-11-05T07:00:00Z'));
        final store = InMemoryStore({
          'prayer_days_9541': fixtureJson,
          'prayer_days_9541_fetched_at': '2026-10-01T07:00:00.000Z',
        });
        final api = _MockDiyanetApi();

        when(
          () => api.fetchPrayerDaysJson('9541'),
        ).thenThrow(
          const DiyanetApiException(
            kind: DiyanetApiErrorKind.network,
            message: 'Ağ hatası',
          ),
        );

        final repository = DefaultPrayerTimesRepository(
          api: api,
          store: store,
          clock: clock,
        );

        expect(
          () => repository.load(istanbulWithoutCoordinates),
          throwsA(
            isA<PrayerTimesException>().having(
              (e) => e.message,
              'message',
              equals('Vakitler alınamadı: internet bağlantısı gerekiyor'),
            ),
          ),
        );
      },
    );

    test(
      'Senaryo 11: Farklı ilçeler farklı anahtar kullanır, birbirini ezmez',
      () async {
        final clock = FixedClock(DateTime.parse('2026-10-01T07:00:00Z'));
        final store = InMemoryStore();
        final api = _MockDiyanetApi();

        when(
          () => api.fetchPrayerDaysJson('9541'),
        ).thenAnswer((_) async => fixtureJson);
        when(
          () => api.fetchPrayerDaysJson('9206'),
        ).thenAnswer((_) async => fixtureJson);

        const ankaraLocation = SelectedLocation(
          cityId: '506',
          cityName: 'ANKARA',
          districtId: '9206',
          districtName: 'ANKARA',
        );

        final repository = DefaultPrayerTimesRepository(
          api: api,
          store: store,
          clock: clock,
        );

        await repository.load(istanbulWithCoordinates);
        await repository.load(ankaraLocation);

        expect(await store.getString('prayer_days_9541'), isNotNull);
        expect(await store.getString('prayer_days_9206'), isNotNull);
        expect(await store.getString('prayer_days_9541_fetched_at'), isNotNull);
        expect(await store.getString('prayer_days_9206_fetched_at'), isNotNull);
      },
    );

    test(
      'önbellekteki fetched_at bozuk olduğunda null sayılır ve önbellek döner',
      () async {
        final clock = FixedClock(DateTime.parse('2026-10-01T07:00:00Z'));
        final store = InMemoryStore({
          'prayer_days_9541': fixtureJson,
          'prayer_days_9541_fetched_at': 'bozuk_tarih',
        });
        final api = _MockDiyanetApi();

        final repository = DefaultPrayerTimesRepository(
          api: api,
          store: store,
          clock: clock,
        );

        final result = await repository.load(istanbulWithCoordinates);

        expect(result.source, equals(PrayerDataSource.cache));
        expect(result.fetchedAt, isNull);
        verifyNever(() => api.fetchPrayerDaysJson(any()));
      },
    );

    test(
      'önbellekteki veri JSON dizi olmadığında yok sayılır ve API çağrılır',
      () async {
        final clock = FixedClock(DateTime.parse('2026-10-01T07:00:00Z'));
        final store = InMemoryStore({
          'prayer_days_9541': '{"gecersiz": "nesne"}',
          'prayer_days_9541_fetched_at': '2026-10-01T07:00:00.000Z',
        });
        final api = _MockDiyanetApi();

        when(
          () => api.fetchPrayerDaysJson('9541'),
        ).thenAnswer((_) async => fixtureJson);

        final repository = DefaultPrayerTimesRepository(
          api: api,
          store: store,
          clock: clock,
        );

        final result = await repository.load(istanbulWithCoordinates);

        expect(result.source, equals(PrayerDataSource.diyanet));
        verify(() => api.fetchPrayerDaysJson('9541')).called(1);
      },
    );

    test(
      'DiyanetApi beklenmeyen istisna attığında yutulmaz ve fırlatılır',
      () async {
        final clock = FixedClock(DateTime.parse('2026-10-01T07:00:00Z'));
        final store = InMemoryStore();
        final api = _MockDiyanetApi();

        when(
          () => api.fetchPrayerDaysJson('9541'),
        ).thenThrow(const FormatException('Beklenmeyen JSON formatı'));

        final repository = DefaultPrayerTimesRepository(
          api: api,
          store: store,
          clock: clock,
        );

        expect(
          () => repository.load(istanbulWithCoordinates),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });
}
