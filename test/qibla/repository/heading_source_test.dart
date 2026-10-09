// HeadingSource ve HeadingUnavailableException birim testleri.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/qibla/models/heading_reading.dart';
import 'package:vakit/qibla/repository/heading_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = EventChannel(HeadingSource.channelName);

  tearDown(() {
    messenger.setMockStreamHandler(channel, null);
  });

  group('HeadingUnavailableException', () {
    test('mesajsız toString sınıf adını döndürür', () {
      const exception = HeadingUnavailableException();
      expect(exception.message, isNull);
      expect(exception.toString(), equals('HeadingUnavailableException'));
    });

    test('mesajlı toString mesajı içerir', () {
      const exception = HeadingUnavailableException('no_sensor');
      expect(exception.message, equals('no_sensor'));
      expect(
        exception.toString(),
        equals('HeadingUnavailableException: no_sensor'),
      );
    });
  });

  group('HeadingSource', () {
    test('varsayılan ve özel kanal ile başlatılabilir', () {
      final defaultSource = HeadingSource();
      expect(defaultSource, isA<HeadingSource>());

      const customChannel = EventChannel('custom/channel');
      final customSource = HeadingSource(channel: customChannel);
      expect(customSource, isA<HeadingSource>());
    });

    test('koordinat argümanları native tarafa iletilir', () async {
      Object? receivedArguments;
      messenger.setMockStreamHandler(
        channel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            receivedArguments = arguments;
            events.success(<String, dynamic>{
              'heading': 151.62,
              'accuracy': 3,
              'trueNorth': true,
            });
          },
        ),
      );

      final source = HeadingSource();
      final reading = await source
          .watch(
            latitude: 41.0082,
            longitude: 28.9784,
          )
          .first;

      expect(
        receivedArguments,
        equals(<String, dynamic>{
          'latitude': 41.0082,
          'longitude': 28.9784,
        }),
      );
      expect(
        reading,
        equals(
          const HeadingReading(
            heading: 151.62,
            accuracy: HeadingAccuracy.high,
            trueNorth: true,
          ),
        ),
      );
    });

    test('koordinat verilmediğinde null değerler iletilir', () async {
      Object? receivedArguments;
      messenger.setMockStreamHandler(
        channel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            receivedArguments = arguments;
            events.success(<String, dynamic>{
              'heading': 0,
              'accuracy': 2,
              'trueNorth': false,
            });
          },
        ),
      );

      final source = HeadingSource();
      final reading = await source.watch().first;

      expect(
        receivedArguments,
        equals(<String, dynamic>{
          'latitude': null,
          'longitude': null,
        }),
      );
      expect(
        reading,
        equals(
          const HeadingReading(
            heading: 0,
            accuracy: HeadingAccuracy.medium,
            trueNorth: false,
          ),
        ),
      );
    });

    test(
      'tüm accuracy değerleri ve bilinmeyen değerler doğru eşlenir',
      () async {
        messenger.setMockStreamHandler(
          channel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              // 0: unreliable
              events
                ..success(<String, dynamic>{
                  'heading': 10,
                  'accuracy': 0,
                  'trueNorth': false,
                })
                // 1: low
                ..success(<String, dynamic>{
                  'heading': 20,
                  'accuracy': 1,
                  'trueNorth': false,
                })
                // 2: medium
                ..success(<String, dynamic>{
                  'heading': 30,
                  'accuracy': 2,
                  'trueNorth': true,
                })
                // 3: high
                ..success(<String, dynamic>{
                  'heading': 40,
                  'accuracy': 3,
                  'trueNorth': true,
                })
                // 99: bilinmeyen -> unreliable
                ..success(<String, dynamic>{
                  'heading': 50,
                  'accuracy': 99,
                  'trueNorth': false,
                });
            },
          ),
        );

        final source = HeadingSource();
        final readings = await source.watch().take(5).toList();

        expect(readings, hasLength(5));
        expect(readings[0].accuracy, HeadingAccuracy.unreliable);
        expect(readings[1].accuracy, HeadingAccuracy.low);
        expect(readings[2].accuracy, HeadingAccuracy.medium);
        expect(readings[3].accuracy, HeadingAccuracy.high);
        expect(readings[4].accuracy, HeadingAccuracy.unreliable);
      },
    );

    test(
      'no_sensor hatası HeadingUnavailableException olarak iletilir',
      () async {
        messenger.setMockStreamHandler(
          channel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.error(
                code: 'no_sensor',
                message: 'Sensör bulunamadı',
              );
            },
          ),
        );

        final source = HeadingSource();
        expect(
          source.watch(),
          emitsError(
            isA<HeadingUnavailableException>().having(
              (e) => e.message,
              'message',
              equals('Sensör bulunamadı'),
            ),
          ),
        );
      },
    );

    test(
      'no_sensor hatasında mesaj yoksa no_sensor varsayılanı atanır',
      () async {
        messenger.setMockStreamHandler(
          channel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.error(code: 'no_sensor');
            },
          ),
        );

        final source = HeadingSource();
        expect(
          source.watch(),
          emitsError(
            isA<HeadingUnavailableException>().having(
              (e) => e.message,
              'message',
              equals('no_sensor'),
            ),
          ),
        );
      },
    );

    test('farklı bir PlatformException akışa olduğu gibi iletilir', () async {
      messenger.setMockStreamHandler(
        channel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            events.error(
              code: 'sensor_failed',
              message: 'Donanım hatası',
            );
          },
        ),
      );

      final source = HeadingSource();
      expect(
        source.watch(),
        emitsError(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            equals('sensor_failed'),
          ),
        ),
      );
    });

    test(
      'bozuk olaylar akışa HeadingUnavailableException olarak iletilir',
      () async {
        final invalidEvents = <dynamic>[
          'string bir olay',
          12345,
          <String, dynamic>{'accuracy': 3, 'trueNorth': true},
          <String, dynamic>{
            'heading': 'yüz',
            'accuracy': 3,
            'trueNorth': true,
          },
          <String, dynamic>{
            'heading': double.nan,
            'accuracy': 3,
            'trueNorth': true,
          },
          <String, dynamic>{
            'heading': double.infinity,
            'accuracy': 3,
            'trueNorth': true,
          },
          <String, dynamic>{'heading': 180, 'trueNorth': true},
          <String, dynamic>{
            'heading': 180,
            'accuracy': 'high',
            'trueNorth': true,
          },
          <String, dynamic>{'heading': 180, 'accuracy': 3},
          <String, dynamic>{
            'heading': 180,
            'accuracy': 3,
            'trueNorth': 'true',
          },
        ];

        for (final invalid in invalidEvents) {
          messenger.setMockStreamHandler(
            channel,
            MockStreamHandler.inline(
              onListen: (arguments, events) {
                events.success(invalid);
              },
            ),
          );

          final source = HeadingSource();
          await expectLater(
            source.watch(),
            emitsError(isA<HeadingUnavailableException>()),
          );
        }
      },
    );

    test(
      'bozuk olay sonrasında gelen geçerli olay başarıyla işlenir',
      () async {
        messenger.setMockStreamHandler(
          channel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events
                ..success('bozuk_veri')
                ..success(<String, dynamic>{
                  'heading': 180,
                  'accuracy': 2,
                  'trueNorth': true,
                });
            },
          ),
        );

        final source = HeadingSource();
        await expectLater(
          source.watch(),
          emitsInOrder([
            emitsError(isA<HeadingUnavailableException>()),
            equals(
              const HeadingReading(
                heading: 180,
                accuracy: HeadingAccuracy.medium,
                trueNorth: true,
              ),
            ),
          ]),
        );
      },
    );

    test('abonelik iptal edildiğinde onCancel tetiklenir', () async {
      var canceled = false;
      messenger.setMockStreamHandler(
        channel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {},
          onCancel: (arguments) {
            canceled = true;
          },
        ),
      );

      final source = HeadingSource();
      final subscription = source.watch().listen((_) {});
      await subscription.cancel();

      expect(canceled, isTrue);
    });
  });
}
