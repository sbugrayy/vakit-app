// City modeli ve Diyanet JSON çözümleme testleri.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/location/models/city.dart';

void main() {
  group('City Diyanet fixture testleri', () {
    test('sehirler_2.json dosyasından 81 il çözümler', () {
      final file = File('test/fixtures/diyanet/sehirler_2.json');
      final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;

      final cities = json
          .map((item) => City.fromDiyanetJson(item as Map<String, dynamic>))
          .toList();

      expect(cities.length, equals(81));

      final first = cities.first;
      expect(first.id, equals('500'));
      expect(first.name, equals('ADANA'));

      final ankara = cities.firstWhere((c) => c.id == '506');
      expect(ankara.name, equals('ANKARA'));

      final istanbul = cities.firstWhere((c) => c.id == '539');
      expect(istanbul.name, equals('İSTANBUL'));
    });
  });

  group('City.fromDiyanetJson geçerli durumlar', () {
    test('doğru alanları olan JSON nesnesini çözümler', () {
      final city = City.fromDiyanetJson(const {
        'SehirID': '539',
        'SehirAdi': 'İSTANBUL',
      });

      expect(city.id, equals('539'));
      expect(city.name, equals('İSTANBUL'));
    });
  });

  group('City.fromDiyanetJson hata durumları', () {
    test('SehirID eksik olduğunda FormatException fırlatır', () {
      expect(
        () => City.fromDiyanetJson(const {'SehirAdi': 'İSTANBUL'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('SehirID metin olmadığında FormatException fırlatır', () {
      expect(
        () => City.fromDiyanetJson(const {
          'SehirID': 539,
          'SehirAdi': 'İSTANBUL',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('SehirAdi eksik olduğunda FormatException fırlatır', () {
      expect(
        () => City.fromDiyanetJson(const {'SehirID': '539'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('SehirAdi metin olmadığında FormatException fırlatır', () {
      expect(
        () => City.fromDiyanetJson(const {
          'SehirID': '539',
          'SehirAdi': 123,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('City Equatable testleri', () {
    test('aynı id ve ada sahip iki nesne eşittir', () {
      const city1 = City(id: '539', name: 'İSTANBUL');
      const city2 = City(id: '539', name: 'İSTANBUL');

      expect(city1, equals(city2));
      expect(city1.hashCode, equals(city2.hashCode));
      expect(city1.props, equals(['539', 'İSTANBUL']));
    });

    test('id farklı olduğunda nesneler eşit değildir', () {
      const city1 = City(id: '539', name: 'İSTANBUL');
      const city2 = City(id: '506', name: 'İSTANBUL');

      expect(city1, isNot(equals(city2)));
    });

    test('name farklı olduğunda nesneler eşit değildir', () {
      const city1 = City(id: '539', name: 'İSTANBUL');
      const city2 = City(id: '539', name: 'ANKARA');

      expect(city1, isNot(equals(city2)));
    });
  });
}
