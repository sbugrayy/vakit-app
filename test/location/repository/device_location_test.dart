// DeviceLocation ve konum modelleri birim testleri.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/location/models/geo_point.dart';
import 'package:vakit/location/models/geocoded_place.dart';
import 'package:vakit/location/repository/device_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel(DeviceLocation.channelName);

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('Modeller', () {
    test('GeoPoint alanları ve eşitliği doğru çalışır', () {
      const p1 = GeoPoint(latitude: 41.01, longitude: 28.97);
      const p2 = GeoPoint(latitude: 41.01, longitude: 28.97);
      const p3 = GeoPoint(latitude: 39.92, longitude: 32.85);

      expect(p1.latitude, 41.01);
      expect(p1.longitude, 28.97);
      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
      expect(p1.props, equals([41.01, 28.97]));
    });

    test('GeocodedPlace alanları ve eşitliği doğru çalışır', () {
      const place1 = GeocodedPlace(
        province: 'İstanbul',
        district: 'Kadıköy',
      );
      const place2 = GeocodedPlace(
        province: 'İstanbul',
        district: 'Kadıköy',
      );
      const place3 = GeocodedPlace(province: 'Ankara');

      expect(place1.province, 'İstanbul');
      expect(place1.district, 'Kadıköy');
      expect(place1, equals(place2));
      expect(place1, isNot(equals(place3)));
      expect(place1.props, equals(['İstanbul', 'Kadıköy']));
    });

    test('DeviceLocationException alanları ve toString', () {
      const ex1 = DeviceLocationException(
        DeviceLocationError.permissionDenied,
        'İzin verilmedi',
      );
      expect(ex1.error, DeviceLocationError.permissionDenied);
      expect(ex1.message, 'İzin verilmedi');
      expect(
        ex1.toString(),
        'DeviceLocationException(DeviceLocationError.permissionDenied, '
        'İzin verilmedi)',
      );

      const ex2 = DeviceLocationException(DeviceLocationError.unavailable);
      expect(ex2.error, DeviceLocationError.unavailable);
      expect(ex2.message, isNull);
    });
  });

  group('DeviceLocation.requestPermission', () {
    test('başarı durumunda izin sonucunu aktarır', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'requestLocationPermission') {
          return true;
        }
        return null;
      });

      final location = DeviceLocation(channel: channel);
      final result = await location.requestPermission();
      expect(result, isTrue);
    });

    test('izin reddedilince false döner', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return false;
      });

      final location = DeviceLocation(channel: channel);
      final result = await location.requestPermission();
      expect(result, isFalse);
    });

    test('kanal null döndüğünde false döner', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return null;
      });

      final location = DeviceLocation(channel: channel);
      final result = await location.requestPermission();
      expect(result, isFalse);
    });

    test('MissingPluginException durumunda false döner', () async {
      messenger.setMockMethodCallHandler(channel, null);

      final location = DeviceLocation(channel: channel);
      final result = await location.requestPermission();
      expect(result, isFalse);
    });

    test('varsayılan kurucu varsayılan kanalı kullanır', () {
      expect(
        DeviceLocation.channelName,
        'com.sbugrayy.vakit/konum',
      );
      final location = DeviceLocation();
      expect(location, isNotNull);
    });
  });

  group('DeviceLocation.currentLocation', () {
    test('başarı durumunda GeoPoint döner', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getCurrentLocation') {
          return <String, dynamic>{
            'latitude': 41.01,
            'longitude': 28.97,
          };
        }
        return null;
      });

      final location = DeviceLocation(channel: channel);
      final point = await location.currentLocation();

      expect(point.latitude, 41.01);
      expect(point.longitude, 28.97);
    });

    test('num tamsayı koordinatları double a çevirir', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return <String, dynamic>{
          'latitude': 41,
          'longitude': 28,
        };
      });

      final location = DeviceLocation(channel: channel);
      final point = await location.currentLocation();

      expect(point.latitude, 41);
      expect(point.longitude, 28);
    });

    test('permission_denied hatasını permissionDenied e eşler', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(
          code: 'permission_denied',
          message: 'İzin reddedildi',
        );
      });

      final location = DeviceLocation(channel: channel);
      expect(
        location.currentLocation,
        throwsA(
          isA<DeviceLocationException>()
              .having(
                (e) => e.error,
                'error',
                DeviceLocationError.permissionDenied,
              )
              .having(
                (e) => e.message,
                'message',
                'İzin reddedildi',
              ),
        ),
      );
    });

    test('unavailable hatasını unavailable a eşler', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(
          code: 'unavailable',
          message: 'Konum servisi yok',
        );
      });

      final location = DeviceLocation(channel: channel);
      expect(
        location.currentLocation,
        throwsA(
          isA<DeviceLocationException>()
              .having(
                (e) => e.error,
                'error',
                DeviceLocationError.unavailable,
              )
              .having(
                (e) => e.message,
                'message',
                'Konum servisi yok',
              ),
        ),
      );
    });

    test('diğer PlatformException unavailable a eşlenir', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(
          code: 'unknown_error',
          message: 'Bilinmeyen hata',
        );
      });

      final location = DeviceLocation(channel: channel);
      expect(
        location.currentLocation,
        throwsA(
          isA<DeviceLocationException>().having(
            (e) => e.error,
            'error',
            DeviceLocationError.unavailable,
          ),
        ),
      );
    });

    test('MissingPluginException unavailable a eşlenir', () async {
      messenger.setMockMethodCallHandler(channel, null);

      final location = DeviceLocation(channel: channel);
      expect(
        location.currentLocation,
        throwsA(
          isA<DeviceLocationException>().having(
            (e) => e.error,
            'error',
            DeviceLocationError.unavailable,
          ),
        ),
      );
    });

    test('bozuk map (null yanıt) unavailable fırlatır', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => null);

      final location = DeviceLocation(channel: channel);
      expect(
        location.currentLocation,
        throwsA(
          isA<DeviceLocationException>().having(
            (e) => e.error,
            'error',
            DeviceLocationError.unavailable,
          ),
        ),
      );
    });

    test('bozuk map (eksik latitude) unavailable fırlatır', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return <String, dynamic>{'longitude': 28.97};
      });

      final location = DeviceLocation(channel: channel);
      expect(
        location.currentLocation,
        throwsA(
          isA<DeviceLocationException>().having(
            (e) => e.error,
            'error',
            DeviceLocationError.unavailable,
          ),
        ),
      );
    });

    test('bozuk map (eksik longitude) unavailable fırlatır', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return <String, dynamic>{'latitude': 41.01};
      });

      final location = DeviceLocation(channel: channel);
      expect(
        location.currentLocation,
        throwsA(
          isA<DeviceLocationException>().having(
            (e) => e.error,
            'error',
            DeviceLocationError.unavailable,
          ),
        ),
      );
    });

    test('bozuk map (geçersiz tip) unavailable fırlatır', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return <String, dynamic>{
          'latitude': 'gecersiz',
          'longitude': 28.97,
        };
      });

      final location = DeviceLocation(channel: channel);
      expect(
        location.currentLocation,
        throwsA(
          isA<DeviceLocationException>().having(
            (e) => e.error,
            'error',
            DeviceLocationError.unavailable,
          ),
        ),
      );
    });
  });

  group('DeviceLocation.reverseGeocode', () {
    test('başarı durumunda GeocodedPlace döner ve argüman iletir', () async {
      MethodCall? recordedCall;
      messenger.setMockMethodCallHandler(channel, (call) async {
        recordedCall = call;
        return <String, dynamic>{
          'province': 'İSTANBUL',
          'district': 'KADIKÖY',
        };
      });

      final location = DeviceLocation(channel: channel);
      const point = GeoPoint(latitude: 41.01, longitude: 28.97);
      final place = await location.reverseGeocode(point);

      expect(recordedCall, isNotNull);
      expect(recordedCall!.method, 'reverseGeocode');
      final args = recordedCall!.arguments as Map<dynamic, dynamic>;
      expect(args['latitude'], 41.01);
      expect(args['longitude'], 28.97);

      expect(place.province, 'İSTANBUL');
      expect(place.district, 'KADIKÖY');
    });

    test('null il ve ilçe başarıyla GeocodedPlace nesnesine döner', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return <String, dynamic>{
          'province': null,
          'district': null,
        };
      });

      final location = DeviceLocation(channel: channel);
      const point = GeoPoint(latitude: 41.01, longitude: 28.97);
      final place = await location.reverseGeocode(point);

      expect(place.province, isNull);
      expect(place.district, isNull);
    });

    test('PlatformException unavailable fırlatır', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(
          code: 'unavailable',
          message: 'Ters kodlama başarısız',
        );
      });

      final location = DeviceLocation(channel: channel);
      const point = GeoPoint(latitude: 41.01, longitude: 28.97);

      expect(
        () => location.reverseGeocode(point),
        throwsA(
          isA<DeviceLocationException>()
              .having(
                (e) => e.error,
                'error',
                DeviceLocationError.unavailable,
              )
              .having(
                (e) => e.message,
                'message',
                'Ters kodlama başarısız',
              ),
        ),
      );
    });

    test('MissingPluginException unavailable fırlatır', () async {
      messenger.setMockMethodCallHandler(channel, null);

      final location = DeviceLocation(channel: channel);
      const point = GeoPoint(latitude: 41.01, longitude: 28.97);

      expect(
        () => location.reverseGeocode(point),
        throwsA(
          isA<DeviceLocationException>().having(
            (e) => e.error,
            'error',
            DeviceLocationError.unavailable,
          ),
        ),
      );
    });

    test('null yanıt unavailable fırlatır', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => null);

      final location = DeviceLocation(channel: channel);
      const point = GeoPoint(latitude: 41.01, longitude: 28.97);

      expect(
        () => location.reverseGeocode(point),
        throwsA(
          isA<DeviceLocationException>().having(
            (e) => e.error,
            'error',
            DeviceLocationError.unavailable,
          ),
        ),
      );
    });

    test('bozuk map (geçersiz alan tipi) unavailable fırlatır', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return <String, dynamic>{
          'province': 12345,
          'district': 'Kadıköy',
        };
      });

      final location = DeviceLocation(channel: channel);
      const point = GeoPoint(latitude: 41.01, longitude: 28.97);

      expect(
        () => location.reverseGeocode(point),
        throwsA(
          isA<DeviceLocationException>().having(
            (e) => e.error,
            'error',
            DeviceLocationError.unavailable,
          ),
        ),
      );
    });
  });
}
