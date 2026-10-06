// NotificationBridge ve NotificationStatus birim testleri.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/notifications/repository/notification_bridge.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel(NotificationBridge.channelName);

  List<PrayerDay> loadFixtureDays() {
    final file = File('test/fixtures/diyanet/vakitler_9541.json');
    final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    return PrayerDay.listFromDiyanetJson(json);
  }

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('NotificationStatus', () {
    test('alanları doğru saklar ve props listesini üretir', () {
      const status = NotificationStatus(
        notificationsGranted: true,
        exactAlarmAllowed: true,
        enabled: false,
      );

      expect(status.notificationsGranted, isTrue);
      expect(status.exactAlarmAllowed, isTrue);
      expect(status.enabled, isFalse);
      expect(
        status.props,
        equals([true, true, false]),
      );
    });

    test('unavailable sabiti bütün değerleri false olarak içerir', () {
      expect(
        NotificationStatus.unavailable,
        equals(NotificationStatus.unavailable),
      );
      expect(NotificationStatus.unavailable.notificationsGranted, isFalse);
      expect(NotificationStatus.unavailable.exactAlarmAllowed, isFalse);
      expect(NotificationStatus.unavailable.enabled, isFalse);
    });

    test('fromMap geçerli map verisini dönüştürür', () {
      final status = NotificationStatus.fromMap(
        const <String, dynamic>{
          'notificationsGranted': true,
          'exactAlarmAllowed': false,
          'enabled': true,
        },
      );

      expect(status.notificationsGranted, isTrue);
      expect(status.exactAlarmAllowed, isFalse);
      expect(status.enabled, isTrue);
    });

    test('fromMap eksik veya null alanlarda false döner', () {
      final status = NotificationStatus.fromMap(
        const <String, dynamic>{},
      );

      expect(status.notificationsGranted, isFalse);
      expect(status.exactAlarmAllowed, isFalse);
      expect(status.enabled, isFalse);
    });

    test('eşitlik ve hashCode beklenen şekilde çalışır', () {
      const status1 = NotificationStatus(
        notificationsGranted: true,
        exactAlarmAllowed: true,
        enabled: false,
      );
      const status2 = NotificationStatus(
        notificationsGranted: true,
        exactAlarmAllowed: true,
        enabled: false,
      );
      const status3 = NotificationStatus.unavailable;

      expect(status1, equals(status2));
      expect(status1.hashCode, equals(status2.hashCode));
      expect(status1, isNot(equals(status3)));
    });
  });

  group('NotificationBridge.buildPayload', () {
    test('vakitler_9541.json ilk iki günüyle doğru yük oluşturur', () {
      final allDays = loadFixtureDays();
      final twoDays = allDays.take(2).toList();

      final payloadStr = NotificationBridge.buildPayload(
        locationLabel: 'İstanbul',
        days: twoDays,
        districtId: '9541',
      );

      final payload = jsonDecode(payloadStr) as Map<String, dynamic>;

      expect(payload['locationLabel'], equals('İstanbul'));
      expect(payload['districtId'], equals('9541'));
      expect(payload['utcOffsetMinutes'], equals(180));

      final days = payload['days'] as List<dynamic>;
      expect(days.length, equals(2));

      final firstDay = days.first as Map<String, dynamic>;
      expect(firstDay['date'], equals('2026-09-30'));

      final firstTimes = firstDay['times'] as List<dynamic>;
      expect(firstTimes.length, equals(6));

      const expectedLabels = <String>[
        'İmsak',
        'Güneş',
        'Öğle',
        'İkindi',
        'Akşam',
        'Yatsı',
      ];
      const expectedKeys = <String>[
        'imsak',
        'gunes',
        'ogle',
        'ikindi',
        'aksam',
        'yatsi',
      ];

      for (var i = 0; i < 6; i++) {
        final item = firstTimes[i] as Map<String, dynamic>;
        expect(item['key'], equals(expectedKeys[i]));
        expect(item['label'], equals(expectedLabels[i]));
        expect(item['epochMillis'], isA<int>());
      }

      final firstItem = firstTimes.first as Map<String, dynamic>;
      final firstEpoch = firstItem['epochMillis'] as int;
      expect(
        firstEpoch,
        equals(
          DateTime.utc(2026, 9, 30, 2, 28).millisecondsSinceEpoch,
        ),
      );

      final secondDay = days[1] as Map<String, dynamic>;
      expect(secondDay['date'], equals('2026-10-01'));
      final secondTimes = secondDay['times'] as List<dynamic>;
      expect(secondTimes.length, equals(6));
      for (var i = 0; i < 6; i++) {
        final item = secondTimes[i] as Map<String, dynamic>;
        expect(item['key'], equals(expectedKeys[i]));
        expect(item['label'], equals(expectedLabels[i]));
      }
    });

    test(
      'boş gün listesi için utcOffsetMinutes 0 ve boş days döner',
      () {
        final payloadStr = NotificationBridge.buildPayload(
          locationLabel: 'Ankara',
          days: const [],
          districtId: '9158',
        );

        final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
        expect(payload['locationLabel'], equals('Ankara'));
        expect(payload['districtId'], equals('9158'));
        expect(payload['utcOffsetMinutes'], equals(0));
        expect(payload['days'], isEmpty);
      },
    );
  });

  group('NotificationBridge metot çağrıları', () {
    test('varsayılan kurucu varsayılan kanalı kullanır', () async {
      MethodCall? recordedCall;
      messenger.setMockMethodCallHandler(channel, (call) async {
        recordedCall = call;
        return null;
      });

      final bridge = NotificationBridge();
      await bridge.setEnabled(enabled: true);

      expect(recordedCall, isNotNull);
      expect(recordedCall!.method, equals('setEnabled'));
      expect(
        NotificationBridge.channelName,
        equals('com.sbugrayy.vakit/bildirim'),
      );
    });

    test('özel kanal verildiğinde o kanalı kullanır', () async {
      const customChannel = MethodChannel('custom/kanal');
      MethodCall? recordedCall;
      messenger.setMockMethodCallHandler(customChannel, (call) async {
        recordedCall = call;
        return null;
      });

      final bridge = NotificationBridge(channel: customChannel);
      await bridge.setEnabled(enabled: true);

      expect(recordedCall, isNotNull);
      expect(recordedCall!.method, equals('setEnabled'));

      messenger.setMockMethodCallHandler(customChannel, null);
    });

    test('syncSchedule doğru metot ve argümanlarla çağrılır', () async {
      MethodCall? recordedCall;
      messenger.setMockMethodCallHandler(channel, (call) async {
        recordedCall = call;
        return null;
      });

      final allDays = loadFixtureDays();
      final bridge = NotificationBridge(channel: channel);

      await bridge.sync(
        locationLabel: 'İstanbul',
        days: allDays.take(1).toList(),
        enabled: true,
        districtId: '9541',
      );

      expect(recordedCall, isNotNull);
      expect(recordedCall!.method, equals('syncSchedule'));
      final args = recordedCall!.arguments as Map<dynamic, dynamic>;
      expect(args['enabled'], isTrue);
      expect(args['payload'], isA<String>());

      final payload =
          jsonDecode(args['payload'] as String) as Map<String, dynamic>;
      expect(payload['locationLabel'], equals('İstanbul'));
      expect(payload['districtId'], equals('9541'));
    });

    test('setEnabled doğru metot ve argümanla çağrılır', () async {
      MethodCall? recordedCall;
      messenger.setMockMethodCallHandler(channel, (call) async {
        recordedCall = call;
        return null;
      });

      final bridge = NotificationBridge(channel: channel);
      await bridge.setEnabled(enabled: true);

      expect(recordedCall, isNotNull);
      expect(recordedCall!.method, equals('setEnabled'));
      final args = recordedCall!.arguments as Map<dynamic, dynamic>;
      expect(args['enabled'], isTrue);
    });

    test(
      'status dönen map verisini NotificationStatus nesnesine çevirir',
      () async {
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getStatus') {
            return <String, dynamic>{
              'notificationsGranted': true,
              'exactAlarmAllowed': true,
              'enabled': true,
            };
          }
          return null;
        });

        final bridge = NotificationBridge(channel: channel);
        final status = await bridge.status();

        expect(
          status,
          equals(
            const NotificationStatus(
              notificationsGranted: true,
              exactAlarmAllowed: true,
              enabled: true,
            ),
          ),
        );
      },
    );

    test(
      'status kanal map dışı veya null döndüğünde unavailable döner',
      () async {
        messenger.setMockMethodCallHandler(channel, (call) async {
          return null;
        });

        final bridge = NotificationBridge(channel: channel);
        expect(await bridge.status(), equals(NotificationStatus.unavailable));

        messenger.setMockMethodCallHandler(channel, (call) async {
          return 'gecersiz_yanit';
        });

        expect(await bridge.status(), equals(NotificationStatus.unavailable));
      },
    );

    test(
      'requestNotificationPermission doğru metot ve sonucu aktarır',
      () async {
        var returnedValue = true;
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'requestNotificationPermission') {
            return returnedValue;
          }
          return null;
        });

        final bridge = NotificationBridge(channel: channel);

        expect(await bridge.requestNotificationPermission(), isTrue);

        returnedValue = false;
        expect(await bridge.requestNotificationPermission(), isFalse);
      },
    );

    test('requestNotificationPermission null sonuçta false döner', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return null;
      });

      final bridge = NotificationBridge(channel: channel);
      expect(await bridge.requestNotificationPermission(), isFalse);
    });

    test('openExactAlarmSettings doğru metot ve sonucu aktarır', () async {
      var returnedValue = true;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'openExactAlarmSettings') {
          return returnedValue;
        }
        return null;
      });

      final bridge = NotificationBridge(channel: channel);

      expect(await bridge.openExactAlarmSettings(), isTrue);

      returnedValue = false;
      expect(await bridge.openExactAlarmSettings(), isFalse);
    });

    test('openExactAlarmSettings null sonuçta false döner', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return null;
      });

      final bridge = NotificationBridge(channel: channel);
      expect(await bridge.openExactAlarmSettings(), isFalse);
    });
  });

  group('Eklenti bulunamadığında hata yönetimi (MissingPluginException)', () {
    setUp(() {
      messenger.setMockMethodCallHandler(channel, null);
    });

    test('sync sessizce döner', () async {
      final bridge = NotificationBridge(channel: channel);
      await expectLater(
        bridge.sync(
          locationLabel: 'İstanbul',
          days: const [],
          enabled: true,
          districtId: '9541',
        ),
        completes,
      );
    });

    test('setEnabled sessizce döner', () async {
      final bridge = NotificationBridge(channel: channel);
      await expectLater(
        bridge.setEnabled(enabled: false),
        completes,
      );
    });

    test('status unavailable döner', () async {
      final bridge = NotificationBridge(channel: channel);
      final status = await bridge.status();
      expect(status, equals(NotificationStatus.unavailable));
    });

    test('requestNotificationPermission false döner', () async {
      final bridge = NotificationBridge(channel: channel);
      expect(await bridge.requestNotificationPermission(), isFalse);
    });

    test('openExactAlarmSettings false döner', () async {
      final bridge = NotificationBridge(channel: channel);
      expect(await bridge.openExactAlarmSettings(), isFalse);
    });
  });

  group('PlatformException çağırana iletilir', () {
    setUp(() {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(
          code: 'invalid_payload',
          message: 'Geçersiz veri',
        );
      });
    });

    test('sync PlatformException fırlatır', () async {
      final bridge = NotificationBridge(channel: channel);
      expect(
        () => bridge.sync(
          locationLabel: 'İstanbul',
          days: const [],
          enabled: true,
          districtId: '9541',
        ),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            equals('invalid_payload'),
          ),
        ),
      );
    });

    test('setEnabled PlatformException fırlatır', () async {
      final bridge = NotificationBridge(channel: channel);
      expect(
        () => bridge.setEnabled(enabled: true),
        throwsA(isA<PlatformException>()),
      );
    });

    test('status PlatformException fırlatır', () async {
      final bridge = NotificationBridge(channel: channel);
      expect(
        bridge.status,
        throwsA(isA<PlatformException>()),
      );
    });

    test(
      'requestNotificationPermission PlatformException fırlatır',
      () async {
        final bridge = NotificationBridge(channel: channel);
        expect(
          bridge.requestNotificationPermission,
          throwsA(isA<PlatformException>()),
        );
      },
    );

    test('openExactAlarmSettings PlatformException fırlatır', () async {
      final bridge = NotificationBridge(channel: channel);
      expect(
        bridge.openExactAlarmSettings,
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
