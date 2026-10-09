// applyDevTrustedCertificate fonksiyonu testleri.

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/shared/diyanet/dev_certificate.dart';

void main() {
  // Test amaçlı kendinden imzalı X.509 kök CA sertifikası (CN=Vakit Test Root).
  final testCertificatePem = File(
    'test/fixtures/certs/test_root.pem',
  ).readAsStringSync();
  final validBase64Pem = base64Encode(utf8.encode(testCertificatePem));

  group('applyDevTrustedCertificate', () {
    test('isDebug false iken hiçbir şey yapmaz ve false döner', () {
      final dio = Dio();
      final initialAdapter = dio.httpClientAdapter;

      final result = applyDevTrustedCertificate(
        dio,
        base64Pem: validBase64Pem,
        isDebug: false,
      );

      expect(result, isFalse);
      expect(dio.httpClientAdapter, same(initialAdapter));
    });

    test('boş base64Pem verildiğinde hiçbir şey yapmaz ve false döner', () {
      final dio = Dio();
      final initialAdapter = dio.httpClientAdapter;

      final result = applyDevTrustedCertificate(dio);

      expect(result, isFalse);
      expect(dio.httpClientAdapter, same(initialAdapter));
    });

    test('varsayılan parametrelerle ortam değişkeni yokken false döner', () {
      final dio = Dio();
      final initialAdapter = dio.httpClientAdapter;

      final result = applyDevTrustedCertificate(dio);

      expect(result, isFalse);
      expect(dio.httpClientAdapter, same(initialAdapter));
    });

    test(
      'geçerli PEM ve isDebug true iken IOHttpClientAdapter kurar ve '
      'true döner',
      () {
        final dio = Dio();

        final result = applyDevTrustedCertificate(
          dio,
          base64Pem: validBase64Pem,
        );

        expect(result, isTrue);
        expect(dio.httpClientAdapter, isA<IOHttpClientAdapter>());

        final adapter = dio.httpClientAdapter as IOHttpClientAdapter;
        final client = adapter.createHttpClient?.call();
        expect(client, isNotNull);
        client?.close(force: true);
      },
    );

    test('bozuk base64 verildiğinde StateError fırlatır', () {
      final dio = Dio();

      expect(
        () => applyDevTrustedCertificate(
          dio,
          base64Pem: '===bozuk base64===',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('DEV_EXTRA_CA_PEM_B64 geçersiz:'),
          ),
        ),
      );
    });

    test(
      'base64 geçerli ama içeriği sertifika olmadığında StateError fırlatır',
      () {
        final dio = Dio();
        final invalidCertBase64 = base64Encode(
          utf8.encode('Bu bir sertifika verisi degildir'),
        );

        expect(
          () => applyDevTrustedCertificate(
            dio,
            base64Pem: invalidCertBase64,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('DEV_EXTRA_CA_PEM_B64 geçersiz:'),
            ),
          ),
        );
      },
    );
  });
}
