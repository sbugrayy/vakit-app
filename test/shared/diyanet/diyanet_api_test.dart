// DiyanetApi istemcisi ve DiyanetApiException sınıfı testleri.

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/shared/diyanet/diyanet_api.dart';
import 'package:vakit/shared/diyanet/diyanet_api_exception.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  MockHttpClientAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  Dio createDio(
    Future<ResponseBody> Function(RequestOptions options) handler,
  ) {
    return Dio(
      BaseOptions(
        baseUrl: 'https://ezanvakti.emushaf.net',
        responseType: ResponseType.plain,
      ),
    )..httpClientAdapter = MockHttpClientAdapter(handler);
  }

  group('DiyanetApi kurulumu', () {
    test('dio verilmeden varsayılan yapılandırmayla kurulabilir', () {
      final api = DiyanetApi();
      expect(api, isNotNull);
    });

    test('verilen dio nesnesi olduğu gibi kullanılır', () {
      final dio = Dio();
      final api = DiyanetApi(dio: dio);
      expect(api, isNotNull);
    });
  });

  group('DiyanetApi fixture testleri ve yol doğrulaması', () {
    test(
      'fetchCities sehirler_2.json ile 81 il döner ve ANKARA/İSTANBUL içerir',
      () async {
        final fixtureContent = File(
          'test/fixtures/diyanet/sehirler_2.json',
        ).readAsStringSync();
        final dio = createDio((options) async {
          expect(options.path, equals('/sehirler/2'));
          return ResponseBody.fromString(
            fixtureContent,
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        final api = DiyanetApi(dio: dio);
        final cities = await api.fetchCities();

        expect(cities.length, equals(81));
        final ankara = cities.firstWhere((c) => c.id == '506');
        expect(ankara.name, equals('ANKARA'));
        final istanbul = cities.firstWhere((c) => c.id == '539');
        expect(istanbul.name, equals('İSTANBUL'));
      },
    );

    test('fetchCities özel countryId ile doğru yolu kullanır', () async {
      final dio = createDio((options) async {
        expect(options.path, equals('/sehirler/1'));
        return ResponseBody.fromString(
          '[]',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final api = DiyanetApi(dio: dio);
      final cities = await api.fetchCities(countryId: '1');
      expect(cities, isEmpty);
    });

    test(
      'fetchDistricts ilceler_539.json ile 19 ilçe döner ve İSTANBUL içerir',
      () async {
        final fixtureContent = File(
          'test/fixtures/diyanet/ilceler_539.json',
        ).readAsStringSync();
        final dio = createDio((options) async {
          expect(options.path, equals('/ilceler/539'));
          return ResponseBody.fromString(
            fixtureContent,
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        final api = DiyanetApi(dio: dio);
        final districts = await api.fetchDistricts('539');

        expect(districts.length, equals(19));
        final istanbul = districts.firstWhere((d) => d.id == '9541');
        expect(istanbul.name, equals('İSTANBUL'));
      },
    );

    test(
      'fetchPrayerDaysJson vakitler_9541.json ham metnini aynen döner',
      () async {
        final fixtureContent = File(
          'test/fixtures/diyanet/vakitler_9541.json',
        ).readAsStringSync();
        final dio = createDio((options) async {
          expect(options.path, equals('/vakitler/9541'));
          return ResponseBody.fromString(
            fixtureContent,
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        final api = DiyanetApi(dio: dio);
        final rawJson = await api.fetchPrayerDaysJson('9541');

        expect(rawJson, equals(fixtureContent));
      },
    );

    test('fetchPrayerDays vakitler_9541.json ile 32 gün döner', () async {
      final fixtureContent = File(
        'test/fixtures/diyanet/vakitler_9541.json',
      ).readAsStringSync();
      final dio = createDio((options) async {
        expect(options.path, equals('/vakitler/9541'));
        return ResponseBody.fromString(
          fixtureContent,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final api = DiyanetApi(dio: dio);
      final days = await api.fetchPrayerDays('9541');

      expect(days.length, equals(32));
      expect(days.first.date, equals(DateTime.utc(2026, 9, 30)));
    });
  });

  group('DiyanetApi hata yolları (DiyanetApiException)', () {
    test(
      'connectionTimeout durumunda DiyanetApiErrorKind.timeout döner',
      () async {
        final dio = createDio((options) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
            message: 'Zaman aşımı',
          );
        });

        final api = DiyanetApi(dio: dio);
        expect(
          api.fetchCities,
          throwsA(
            isA<DiyanetApiException>()
                .having(
                  (e) => e.kind,
                  'kind',
                  equals(DiyanetApiErrorKind.timeout),
                )
                .having(
                  (e) => e.message,
                  'message',
                  equals('Zaman aşımı'),
                ),
          ),
        );
      },
    );

    test('sendTimeout durumunda DiyanetApiErrorKind.timeout döner', () async {
      final dio = createDio((options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.sendTimeout,
        );
      });

      final api = DiyanetApi(dio: dio);
      expect(
        api.fetchCities,
        throwsA(
          isA<DiyanetApiException>()
              .having(
                (e) => e.kind,
                'kind',
                equals(DiyanetApiErrorKind.timeout),
              )
              .having(
                (e) => e.message,
                'message',
                equals('İstek zaman aşımına uğradı'),
              ),
        ),
      );
    });

    test(
      'receiveTimeout durumunda DiyanetApiErrorKind.timeout döner',
      () async {
        final dio = createDio((options) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.receiveTimeout,
          );
        });

        final api = DiyanetApi(dio: dio);
        expect(
          api.fetchCities,
          throwsA(
            isA<DiyanetApiException>().having(
              (e) => e.kind,
              'kind',
              equals(DiyanetApiErrorKind.timeout),
            ),
          ),
        );
      },
    );

    test(
      'transformTimeout durumunda DiyanetApiErrorKind.timeout döner',
      () async {
        final dio = createDio((options) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.transformTimeout,
          );
        });

        final api = DiyanetApi(dio: dio);
        expect(
          api.fetchCities,
          throwsA(
            isA<DiyanetApiException>()
                .having(
                  (e) => e.kind,
                  'kind',
                  equals(DiyanetApiErrorKind.timeout),
                )
                .having(
                  (e) => e.message,
                  'message',
                  equals('İstek zaman aşımına uğradı'),
                ),
          ),
        );
      },
    );

    test(
      'connectionError durumunda DiyanetApiErrorKind.network döner',
      () async {
        final dio = createDio((options) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'Bağlantı hatası',
          );
        });

        final api = DiyanetApi(dio: dio);
        expect(
          api.fetchCities,
          throwsA(
            isA<DiyanetApiException>()
                .having(
                  (e) => e.kind,
                  'kind',
                  equals(DiyanetApiErrorKind.network),
                )
                .having(
                  (e) => e.message,
                  'message',
                  equals('Bağlantı hatası'),
                ),
          ),
        );
      },
    );

    test('diğer DioException durumlarında network döner', () async {
      final dio = createDio((options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
        );
      });

      final api = DiyanetApi(dio: dio);
      expect(
        api.fetchCities,
        throwsA(
          isA<DiyanetApiException>()
              .having(
                (e) => e.kind,
                'kind',
                equals(DiyanetApiErrorKind.network),
              )
              .having(
                (e) => e.message,
                'message',
                equals('Ağ hatası'),
              ),
        ),
      );
    });

    test('500 durum kodunda badResponse döner', () async {
      final dio = createDio((options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 500,
          ),
        );
      });

      final api = DiyanetApi(dio: dio);
      expect(
        api.fetchCities,
        throwsA(
          isA<DiyanetApiException>()
              .having(
                (e) => e.kind,
                'kind',
                equals(DiyanetApiErrorKind.badResponse),
              )
              .having(
                (e) => e.message,
                'message',
                contains('500'),
              ),
        ),
      );
    });

    test(
      'badResponse durumunda statusCode yoksa durum bilinmiyor yazar',
      () async {
        final dio = createDio((options) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
          );
        });

        final api = DiyanetApi(dio: dio);
        expect(
          api.fetchCities,
          throwsA(
            isA<DiyanetApiException>()
                .having(
                  (e) => e.kind,
                  'kind',
                  equals(DiyanetApiErrorKind.badResponse),
                )
                .having(
                  (e) => e.message,
                  'message',
                  contains('durum bilinmiyor'),
                ),
          ),
        );
      },
    );

    test('200 dışı durum kodu doğrudan döndüğünde badResponse döner', () async {
      final dio =
          Dio(
              BaseOptions(
                baseUrl: 'https://ezanvakti.emushaf.net',
                responseType: ResponseType.plain,
                validateStatus: (status) => true,
              ),
            )
            ..httpClientAdapter = MockHttpClientAdapter((options) async {
              return ResponseBody.fromString('Not Found', 404);
            });

      final api = DiyanetApi(dio: dio);
      expect(
        api.fetchCities,
        throwsA(
          isA<DiyanetApiException>()
              .having(
                (e) => e.kind,
                'kind',
                equals(DiyanetApiErrorKind.badResponse),
              )
              .having(
                (e) => e.message,
                'message',
                contains('404'),
              ),
        ),
      );
    });

    test(
      'yanıt gövdesi metin değilse invalidData döner',
      () async {
        final dio =
            Dio(
                BaseOptions(
                  baseUrl: 'https://ezanvakti.emushaf.net',
                ),
              )
              ..httpClientAdapter = MockHttpClientAdapter((options) async {
                return ResponseBody.fromString('123', 200);
              })
              ..interceptors.add(
                InterceptorsWrapper(
                  onResponse: (response, handler) {
                    response.data = 12345;
                    handler.next(response);
                  },
                ),
              );

        final api = DiyanetApi(dio: dio);
        expect(
          api.fetchCities,
          throwsA(
            isA<DiyanetApiException>().having(
              (e) => e.kind,
              'kind',
              equals(DiyanetApiErrorKind.invalidData),
            ),
          ),
        );
      },
    );

    test(
      'bozuk JSON yanıtında invalidData döner',
      () async {
        final dio = createDio((options) async {
          return ResponseBody.fromString('{gecersiz_json', 200);
        });

        final api = DiyanetApi(dio: dio);
        expect(
          api.fetchCities,
          throwsA(
            isA<DiyanetApiException>().having(
              (e) => e.kind,
              'kind',
              equals(DiyanetApiErrorKind.invalidData),
            ),
          ),
        );
      },
    );

    test(
      'JSON nesne (dizi değil) yanıtında invalidData döner',
      () async {
        final dio = createDio((options) async {
          return ResponseBody.fromString('{"hata": "bulunamadi"}', 200);
        });

        final api = DiyanetApi(dio: dio);
        expect(
          api.fetchCities,
          throwsA(
            isA<DiyanetApiException>().having(
              (e) => e.kind,
              'kind',
              equals(DiyanetApiErrorKind.invalidData),
            ),
          ),
        );
      },
    );

    test(
      'şehir listesi öğesi Map olmadığında invalidData döner',
      () async {
        final dio = createDio((options) async {
          return ResponseBody.fromString('[123]', 200);
        });

        final api = DiyanetApi(dio: dio);
        expect(
          api.fetchCities,
          throwsA(
            isA<DiyanetApiException>().having(
              (e) => e.kind,
              'kind',
              equals(DiyanetApiErrorKind.invalidData),
            ),
          ),
        );
      },
    );

    test(
      'şehir listesinde eksik alan olduğunda invalidData döner',
      () async {
        final dio = createDio((options) async {
          return ResponseBody.fromString('[{"SehirAdi": "ANKARA"}]', 200);
        });

        final api = DiyanetApi(dio: dio);
        expect(
          api.fetchCities,
          throwsA(
            isA<DiyanetApiException>().having(
              (e) => e.kind,
              'kind',
              equals(DiyanetApiErrorKind.invalidData),
            ),
          ),
        );
      },
    );

    test(
      'ilçe listesi öğesi Map olmadığında invalidData döner',
      () async {
        final dio = createDio((options) async {
          return ResponseBody.fromString('[123]', 200);
        });

        final api = DiyanetApi(dio: dio);
        expect(
          () => api.fetchDistricts('539'),
          throwsA(
            isA<DiyanetApiException>().having(
              (e) => e.kind,
              'kind',
              equals(DiyanetApiErrorKind.invalidData),
            ),
          ),
        );
      },
    );

    test(
      'boş vakit dizisi [] durumunda invalidData döner',
      () async {
        final dio = createDio((options) async {
          return ResponseBody.fromString('[]', 200);
        });

        final api = DiyanetApi(dio: dio);
        expect(
          () => api.fetchPrayerDaysJson('9541'),
          throwsA(
            isA<DiyanetApiException>().having(
              (e) => e.kind,
              'kind',
              equals(DiyanetApiErrorKind.invalidData),
            ),
          ),
        );
      },
    );

    test(
      'vakit listesi FormatException fırlattığında invalidData döner',
      () async {
        final dio = createDio((options) async {
          return ResponseBody.fromString(
            '[{"MiladiTarihKisa": "gecersiz"}]',
            200,
          );
        });

        final api = DiyanetApi(dio: dio);
        expect(
          () => api.fetchPrayerDays('9541'),
          throwsA(
            isA<DiyanetApiException>().having(
              (e) => e.kind,
              'kind',
              equals(DiyanetApiErrorKind.invalidData),
            ),
          ),
        );
      },
    );
  });

  group('DiyanetApiException testleri', () {
    test('toString kind ve message içerir', () {
      const exception = DiyanetApiException(
        kind: DiyanetApiErrorKind.network,
        message: 'Ağ bağlantısı koptu',
      );

      expect(
        exception.toString(),
        equals(
          'DiyanetApiException(DiyanetApiErrorKind.network, '
          'Ağ bağlantısı koptu)',
        ),
      );
      expect(exception.kind, equals(DiyanetApiErrorKind.network));
      expect(exception.message, equals('Ağ bağlantısı koptu'));
    });
  });
}
