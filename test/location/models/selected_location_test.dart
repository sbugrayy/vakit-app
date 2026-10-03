// SelectedLocation modelinin JSON serileştirme, koordinat mantığı ve
// Equatable eşitlik sözleşmesini doğrulayan birim testleri.

import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/location/models/selected_location.dart';

void main() {
  group('SelectedLocation', () {
    const sampleLocation = SelectedLocation(
      cityId: '506',
      cityName: 'İstanbul',
      districtId: '9541',
      districtName: 'Kadıköy',
      latitude: 40.99,
      longitude: 29.02,
    );

    test('hasCoordinates sadece her iki koordinat da doluyken doğrudur', () {
      expect(sampleLocation.hasCoordinates, isTrue);

      const noCoordinates = SelectedLocation(
        cityId: '506',
        cityName: 'İstanbul',
        districtId: '9541',
        districtName: 'Kadıköy',
      );
      expect(noCoordinates.hasCoordinates, isFalse);

      const onlyLatitude = SelectedLocation(
        cityId: '506',
        cityName: 'İstanbul',
        districtId: '9541',
        districtName: 'Kadıköy',
        latitude: 40.99,
      );
      expect(onlyLatitude.hasCoordinates, isFalse);

      const onlyLongitude = SelectedLocation(
        cityId: '506',
        cityName: 'İstanbul',
        districtId: '9541',
        districtName: 'Kadıköy',
        longitude: 29.02,
      );
      expect(onlyLongitude.hasCoordinates, isFalse);
    });

    test('koordinatlı model için gidiş-dönüş JSON doğrulaması', () {
      final json = sampleLocation.toJson();
      final recreated = SelectedLocation.fromJson(json);

      expect(recreated, equals(sampleLocation));
    });

    test('koordinatsız modelde JSON alanları null olur ve doğru okunur', () {
      const location = SelectedLocation(
        cityId: '506',
        cityName: 'İstanbul',
        districtId: '9541',
        districtName: 'Kadıköy',
      );
      final json = location.toJson();

      expect(json['latitude'], isNull);
      expect(json['longitude'], isNull);

      final recreated = SelectedLocation.fromJson(json);
      expect(recreated, equals(location));
      expect(recreated.latitude, isNull);
      expect(recreated.longitude, isNull);
    });

    test('tam sayı koordinatlar double tipine dönüştürülür', () {
      final json = <String, dynamic>{
        'cityId': '506',
        'cityName': 'İstanbul',
        'districtId': '9541',
        'districtName': 'Kadıköy',
        'latitude': 41,
        'longitude': 29,
      };

      final location = SelectedLocation.fromJson(json);
      expect(location.latitude, equals(41));
      expect(location.longitude, equals(29));
    });

    group('fromJson FormatException fırlatma durumları', () {
      Map<String, dynamic> createValidMap() {
        return <String, dynamic>{
          'cityId': '506',
          'cityName': 'İstanbul',
          'districtId': '9541',
          'districtName': 'Kadıköy',
          'latitude': 40.99,
          'longitude': 29.02,
        };
      }

      test('cityId eksik olduğunda hata fırlatır', () {
        final map = createValidMap()..remove('cityId');
        expect(
          () => SelectedLocation.fromJson(map),
          throwsA(isA<FormatException>()),
        );
      });

      test('cityId tipi geçersiz olduğunda hata fırlatır', () {
        final map = createValidMap()..['cityId'] = 506;
        expect(
          () => SelectedLocation.fromJson(map),
          throwsA(isA<FormatException>()),
        );
      });

      test('cityName eksik olduğunda hata fırlatır', () {
        final map = createValidMap()..remove('cityName');
        expect(
          () => SelectedLocation.fromJson(map),
          throwsA(isA<FormatException>()),
        );
      });

      test('cityName tipi geçersiz olduğunda hata fırlatır', () {
        final map = createValidMap()..['cityName'] = 123;
        expect(
          () => SelectedLocation.fromJson(map),
          throwsA(isA<FormatException>()),
        );
      });

      test('districtId eksik olduğunda hata fırlatır', () {
        final map = createValidMap()..remove('districtId');
        expect(
          () => SelectedLocation.fromJson(map),
          throwsA(isA<FormatException>()),
        );
      });

      test('districtId tipi geçersiz olduğunda hata fırlatır', () {
        final map = createValidMap()..['districtId'] = 9541;
        expect(
          () => SelectedLocation.fromJson(map),
          throwsA(isA<FormatException>()),
        );
      });

      test('districtName eksik olduğunda hata fırlatır', () {
        final map = createValidMap()..remove('districtName');
        expect(
          () => SelectedLocation.fromJson(map),
          throwsA(isA<FormatException>()),
        );
      });

      test('districtName tipi geçersiz olduğunda hata fırlatır', () {
        final map = createValidMap()..['districtName'] = 456;
        expect(
          () => SelectedLocation.fromJson(map),
          throwsA(isA<FormatException>()),
        );
      });

      test('latitude tipi geçersiz olduğunda hata fırlatır', () {
        final map = createValidMap()..['latitude'] = 'gecersiz';
        expect(
          () => SelectedLocation.fromJson(map),
          throwsA(isA<FormatException>()),
        );
      });

      test('longitude tipi geçersiz olduğunda hata fırlatır', () {
        final map = createValidMap()..['longitude'] = 'gecersiz';
        expect(
          () => SelectedLocation.fromJson(map),
          throwsA(isA<FormatException>()),
        );
      });
    });

    test('Equatable eşitliği ve props listesini doğrular', () {
      const location1 = SelectedLocation(
        cityId: '506',
        cityName: 'İstanbul',
        districtId: '9541',
        districtName: 'Kadıköy',
        latitude: 40.99,
        longitude: 29.02,
      );

      const location2 = SelectedLocation(
        cityId: '506',
        cityName: 'İstanbul',
        districtId: '9541',
        districtName: 'Kadıköy',
        latitude: 40.99,
        longitude: 29.02,
      );

      const differentLocation = SelectedLocation(
        cityId: '506',
        cityName: 'İstanbul',
        districtId: '9542',
        districtName: 'Üsküdar',
        latitude: 41.02,
        longitude: 29.01,
      );

      expect(location1, equals(location2));
      expect(location1.hashCode, equals(location2.hashCode));
      expect(location1, isNot(equals(differentLocation)));

      expect(
        location1.props,
        equals(<Object?>[
          '506',
          'İstanbul',
          '9541',
          'Kadıköy',
          40.99,
          29.02,
        ]),
      );
    });
  });
}
