// District modeli ve Diyanet JSON çözümleme testleri.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/location/models/district.dart';

void main() {
  group('District Diyanet fixture testleri', () {
    test('ilceler_539.json dosyasından 19 ilçe çözümler', () {
      final file = File('test/fixtures/diyanet/ilceler_539.json');
      final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;

      final districts = json
          .map((item) => District.fromDiyanetJson(item as Map<String, dynamic>))
          .toList();

      expect(districts.length, equals(19));

      final first = districts.first;
      expect(first.id, equals('9535'));
      expect(first.name, equals('ARNAVUTKOY'));

      final istanbul = districts.firstWhere((d) => d.id == '9541');
      expect(istanbul.name, equals('İSTANBUL'));
    });
  });

  group('District.fromDiyanetJson geçerli durumlar', () {
    test('doğru alanları olan JSON nesnesini çözümler', () {
      final district = District.fromDiyanetJson(const {
        'IlceID': '9541',
        'IlceAdi': 'İSTANBUL',
      });

      expect(district.id, equals('9541'));
      expect(district.name, equals('İSTANBUL'));
    });
  });

  group('District.fromDiyanetJson hata durumları', () {
    test('IlceID eksik olduğunda FormatException fırlatır', () {
      expect(
        () => District.fromDiyanetJson(const {'IlceAdi': 'İSTANBUL'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('IlceID metin olmadığında FormatException fırlatır', () {
      expect(
        () => District.fromDiyanetJson(const {
          'IlceID': 9541,
          'IlceAdi': 'İSTANBUL',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('IlceAdi eksik olduğunda FormatException fırlatır', () {
      expect(
        () => District.fromDiyanetJson(const {'IlceID': '9541'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('IlceAdi metin olmadığında FormatException fırlatır', () {
      expect(
        () => District.fromDiyanetJson(const {
          'IlceID': 9541,
          'IlceAdi': 9541,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('District Equatable testleri', () {
    test('aynı id ve ada sahip iki nesne eşittir', () {
      const district1 = District(id: '9541', name: 'İSTANBUL');
      const district2 = District(id: '9541', name: 'İSTANBUL');

      expect(district1, equals(district2));
      expect(district1.hashCode, equals(district2.hashCode));
      expect(district1.props, equals(['9541', 'İSTANBUL']));
    });

    test('id farklı olduğunda nesneler eşit değildir', () {
      const district1 = District(id: '9541', name: 'İSTANBUL');
      const district2 = District(id: '9535', name: 'İSTANBUL');

      expect(district1, isNot(equals(district2)));
    });

    test('name farklı olduğunda nesneler eşit değildir', () {
      const district1 = District(id: '9541', name: 'İSTANBUL');
      const district2 = District(id: '9541', name: 'KADIKÖY');

      expect(district1, isNot(equals(district2)));
    });
  });
}
