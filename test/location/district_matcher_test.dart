// matchCity ve matchDistrict fonksiyonları için birim testler.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/location/district_matcher.dart';
import 'package:vakit/location/models/city.dart';
import 'package:vakit/location/models/district.dart';

List<City> _loadCities() {
  final file = File('test/fixtures/diyanet/sehirler_2.json');
  final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return json
      .map((item) => City.fromDiyanetJson(item as Map<String, dynamic>))
      .toList();
}

List<District> _loadDistricts(String filename) {
  final file = File('test/fixtures/diyanet/$filename');
  final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return json
      .map((item) => District.fromDiyanetJson(item as Map<String, dynamic>))
      .toList();
}

void main() {
  late final List<City> cities;
  late final List<District> istanbulDistricts;
  late final List<District> ankaraDistricts;
  late final List<District> vanDistricts;

  setUpAll(() {
    cities = _loadCities();
    istanbulDistricts = _loadDistricts('ilceler_539.json');
    ankaraDistricts = _loadDistricts('ilceler_506.json');
    vanDistricts = _loadDistricts('ilceler_577.json');
  });

  group('matchCity', () {
    test('farklı yazımlardaki İstanbul adını doğru eşler', () {
      expect(matchCity(cities, 'İstanbul')?.id, equals('539'));
      expect(matchCity(cities, 'ISTANBUL')?.id, equals('539'));
      expect(matchCity(cities, 'istanbul')?.id, equals('539'));
    });

    test('İzmir adını doğru eşler', () {
      expect(matchCity(cities, 'İzmir')?.id, equals('540'));
    });

    test('İli veya Province eki içeren sorguları doğru eşler', () {
      expect(matchCity(cities, 'İstanbul İli')?.id, equals('539'));
      expect(matchCity(cities, 'Ankara Province')?.id, equals('506'));
    });

    test('eşleşme bulunamadığında veya liste boşken null döner', () {
      expect(matchCity(cities, 'Atlantis'), isNull);
      expect(matchCity(const [], 'İstanbul'), isNull);
    });
  });

  group('matchDistrict İstanbul testleri', () {
    test('farklı ilçe adlarını ve ASCII yazımı doğru eşler', () {
      final basaksehir = matchDistrict(
        istanbulDistricts,
        cityName: 'İstanbul',
        districtName: 'Başakşehir',
      );
      expect(basaksehir?.id, equals('17866'));

      final arnavutkoy = matchDistrict(
        istanbulDistricts,
        cityName: 'İstanbul',
        districtName: 'Arnavutköy',
      );
      expect(arnavutkoy?.id, equals('9535'));

      final sile = matchDistrict(
        istanbulDistricts,
        cityName: 'İstanbul',
        districtName: 'Şile',
      );
      expect(sile?.id, equals('9547'));
    });

    test('merkez ilçeler (Kadıköy) ve null ilçe adında merkeze düşer', () {
      final kadikoy = matchDistrict(
        istanbulDistricts,
        cityName: 'İstanbul',
        districtName: 'Kadıköy',
      );
      expect(kadikoy?.id, equals('9541'));

      final nullDistrict = matchDistrict(
        istanbulDistricts,
        cityName: 'İstanbul',
      );
      expect(nullDistrict?.id, equals('9541'));

      final emptyDistrict = matchDistrict(
        istanbulDistricts,
        cityName: 'İstanbul',
        districtName: '   ',
      );
      expect(emptyDistrict?.id, equals('9541'));
    });

    test('cityName İli eki içerse bile merkeze doğru eşler', () {
      final match = matchDistrict(
        istanbulDistricts,
        cityName: 'İstanbul İli',
        districtName: 'Kadıköy',
      );
      expect(match?.id, equals('9541'));
    });
  });

  group('matchDistrict Ankara testleri', () {
    test('ASCII ve ek içeren ilçeleri doğru eşler', () {
      final cubuk = matchDistrict(
        ankaraDistricts,
        cityName: 'Ankara',
        districtName: 'Çubuk',
      );
      expect(cubuk?.id, equals('9211'));

      final cankaya = matchDistrict(
        ankaraDistricts,
        cityName: 'Ankara',
        districtName: 'Çankaya',
      );
      expect(cankaya?.id, equals('9206'));

      final kahramankazan = matchDistrict(
        ankaraDistricts,
        cityName: 'Ankara',
        districtName: 'Kahramankazan',
      );
      expect(kahramankazan?.id, equals('9217'));

      final polatliIlcesi = matchDistrict(
        ankaraDistricts,
        cityName: 'Ankara',
        districtName: 'Polatlı İlçesi',
      );
      expect(polatliIlcesi?.id, equals('9220'));

      final polatliDistrict = matchDistrict(
        ankaraDistricts,
        cityName: 'Ankara',
        districtName: 'Polatlı District',
      );
      expect(polatliDistrict?.id, equals('9220'));
    });
  });

  group('matchDistrict Van testleri', () {
    test('parantezli ilçe adını ve merkez eşlemesini doğru yapar', () {
      final edremit = matchDistrict(
        vanDistricts,
        cityName: 'Van',
        districtName: 'Edremit',
      );
      expect(edremit?.id, equals('9924'));

      final ipekyolu = matchDistrict(
        vanDistricts,
        cityName: 'Van',
        districtName: 'İpekyolu',
      );
      expect(ipekyolu?.id, equals('9930'));

      final ercis = matchDistrict(
        vanDistricts,
        cityName: 'Van',
        districtName: 'Erciş',
      );
      expect(ercis?.id, equals('9925'));

      final vanMerkez = matchDistrict(
        vanDistricts,
        cityName: 'Van',
        districtName: 'Van Merkez',
      );
      expect(vanMerkez?.id, equals('9930'));
    });
  });

  group('matchDistrict eşleşmeme ve merkezi olmayan durumlar', () {
    test('merkezi olmayan listede ve eşleşme yoksa null döner', () {
      const fallbackDistricts = [
        District(id: '1', name: 'Aliağa'),
        District(id: '2', name: 'Bergama'),
      ];

      final noMatch = matchDistrict(
        fallbackDistricts,
        cityName: 'İzmir',
        districtName: 'Bilinmeyen',
      );
      expect(noMatch, isNull);

      final noDistrict = matchDistrict(
        fallbackDistricts,
        cityName: 'İzmir',
      );
      expect(noDistrict, isNull);

      final emptyList = matchDistrict(
        const [],
        cityName: 'İzmir',
        districtName: 'Aliağa',
      );
      expect(emptyList, isNull);
    });
  });
}
