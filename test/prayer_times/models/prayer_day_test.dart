// PrayerDay modeli ve Diyanet JSON çözümleme testleri.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/prayer_times/models/prayer.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';

void main() {
  Map<String, dynamic> sampleJson({
    String miladiTarihKisa = '30.09.2026',
    dynamic greenwichOrtalamaZamani = 3.0,
    dynamic hicriTarihUzun = '19 Rebiulahir 1448',
    dynamic imsak = '05:28',
    dynamic gunes = '06:52',
    dynamic ogle = '12:59',
    dynamic ikindi = '16:18',
    dynamic aksam = '18:56',
    dynamic yatsi = '20:15',
    dynamic kibleSaati = '11:32',
  }) {
    final map = <String, dynamic>{
      'MiladiTarihKisa': miladiTarihKisa,
      'GreenwichOrtalamaZamani': greenwichOrtalamaZamani,
      'HicriTarihUzun': hicriTarihUzun,
      'Imsak': imsak,
      'Gunes': gunes,
      'Ogle': ogle,
      'Ikindi': ikindi,
      'Aksam': aksam,
      'Yatsi': yatsi,
    };
    if (kibleSaati != null) {
      map['KibleSaati'] = kibleSaati;
    }
    return map;
  }

  group('PrayerDay Diyanet fixture testleri', () {
    test('vakitler_9541.json dosyasını doğru çözümler', () {
      final file = File('test/fixtures/diyanet/vakitler_9541.json');
      final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      final days = PrayerDay.listFromDiyanetJson(json);

      expect(days.length, equals(32));

      final firstDay = days.first;
      expect(firstDay.date, equals(DateTime.utc(2026, 9, 30)));
      expect(
        firstDay.timeOf(Prayer.imsak),
        equals(DateTime.utc(2026, 9, 30, 2, 28)),
      );
      expect(
        firstDay.timeOf(Prayer.gunes),
        equals(DateTime.utc(2026, 9, 30, 3, 52)),
      );
      expect(
        firstDay.timeOf(Prayer.ogle),
        equals(DateTime.utc(2026, 9, 30, 9, 59)),
      );
      expect(
        firstDay.timeOf(Prayer.ikindi),
        equals(DateTime.utc(2026, 9, 30, 13, 18)),
      );
      expect(
        firstDay.timeOf(Prayer.aksam),
        equals(DateTime.utc(2026, 9, 30, 15, 56)),
      );
      expect(
        firstDay.timeOf(Prayer.yatsi),
        equals(DateTime.utc(2026, 9, 30, 17, 15)),
      );
      expect(
        firstDay.qiblaTime,
        equals(DateTime.utc(2026, 9, 30, 8, 32)),
      );
      expect(firstDay.hijriDate, equals('19 Rebiulahir 1448'));
      expect(firstDay.utcOffset, equals(const Duration(hours: 3)));
    });

    for (final fixtureId in ['9541', '9206', '9930']) {
      test(
        'fixture $fixtureId günleri kronolojik ve vakitler artan sırada',
        () {
          final file = File('test/fixtures/diyanet/vakitler_$fixtureId.json');
          final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;
          final days = PrayerDay.listFromDiyanetJson(json);

          expect(days, isNotEmpty);

          for (var i = 0; i < days.length - 1; i++) {
            final current = days[i];
            final next = days[i + 1];
            expect(
              next.date,
              equals(current.date.add(const Duration(days: 1))),
            );
          }

          for (final day in days) {
            final imsak = day.timeOf(Prayer.imsak);
            final gunes = day.timeOf(Prayer.gunes);
            final ogle = day.timeOf(Prayer.ogle);
            final ikindi = day.timeOf(Prayer.ikindi);
            final aksam = day.timeOf(Prayer.aksam);
            final yatsi = day.timeOf(Prayer.yatsi);

            expect(imsak.isBefore(gunes), isTrue);
            expect(gunes.isBefore(ogle), isTrue);
            expect(ogle.isBefore(ikindi), isTrue);
            expect(ikindi.isBefore(aksam), isTrue);
            expect(aksam.isBefore(yatsi), isTrue);
          }
        },
      );
    }
  });

  group('PrayerDay elle kurulmuş JSON testleri', () {
    test('ofset 2.0 doğru uygulanır', () {
      final day = PrayerDay.fromDiyanetJson(
        sampleJson(greenwichOrtalamaZamani: 2.0),
      );
      expect(day.utcOffset, equals(const Duration(hours: 2)));
      expect(
        day.timeOf(Prayer.imsak),
        equals(DateTime.utc(2026, 9, 30, 3, 28)),
      );
    });

    test('ofset 5.5 doğru uygulanır', () {
      final day = PrayerDay.fromDiyanetJson(
        sampleJson(
          greenwichOrtalamaZamani: 5.5,
          imsak: '06:00',
        ),
      );
      expect(day.utcOffset, equals(const Duration(hours: 5, minutes: 30)));
      expect(
        day.timeOf(Prayer.imsak),
        equals(DateTime.utc(2026, 9, 30, 0, 30)),
      );
    });

    test('tam sayı ofset kabul edilir', () {
      final day = PrayerDay.fromDiyanetJson(
        sampleJson(greenwichOrtalamaZamani: 3),
      );
      expect(day.utcOffset, equals(const Duration(hours: 3)));
      expect(
        day.timeOf(Prayer.imsak),
        equals(DateTime.utc(2026, 9, 30, 2, 28)),
      );
    });

    test('KibleSaati yoksa qiblaTime null olur', () {
      final jsonWithoutQibla = sampleJson()..remove('KibleSaati');
      final day = PrayerDay.fromDiyanetJson(jsonWithoutQibla);
      expect(day.qiblaTime, isNull);
    });

    test('KibleSaati boş metin ise qiblaTime null olur', () {
      final dayEmpty = PrayerDay.fromDiyanetJson(
        sampleJson(kibleSaati: ''),
      );
      expect(dayEmpty.qiblaTime, isNull);

      final dayWhitespace = PrayerDay.fromDiyanetJson(
        sampleJson(kibleSaati: '   '),
      );
      expect(dayWhitespace.qiblaTime, isNull);
    });
  });

  group('PrayerDay FormatException hata durumları', () {
    test('eksik vakit alanı FormatException fırlatır', () {
      final prayerKeys = [
        'Imsak',
        'Gunes',
        'Ogle',
        'Ikindi',
        'Aksam',
        'Yatsi',
      ];
      for (final field in prayerKeys) {
        final invalidJson = sampleJson()..remove(field);
        expect(
          () => PrayerDay.fromDiyanetJson(invalidJson),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains(field),
            ),
          ),
        );
      }
    });

    test('sayı veya metin olmayan vakit alanı FormatException fırlatır', () {
      expect(
        () => PrayerDay.fromDiyanetJson(sampleJson(imsak: 528)),
        throwsA(isA<FormatException>()),
      );
    });

    test('25:61 gibi geçersiz vakit FormatException fırlatır', () {
      expect(
        () => PrayerDay.fromDiyanetJson(sampleJson(imsak: '25:61')),
        throwsA(isA<FormatException>()),
      );
    });

    test('7:5 gibi tek haneli vakit FormatException fırlatır', () {
      expect(
        () => PrayerDay.fromDiyanetJson(sampleJson(imsak: '7:5')),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PrayerDay.fromDiyanetJson(sampleJson(imsak: '07:5')),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PrayerDay.fromDiyanetJson(sampleJson(imsak: '7:05')),
        throwsA(isA<FormatException>()),
      );
    });

    test('bozuk tarih formatları FormatException fırlatır', () {
      expect(
        () => PrayerDay.fromDiyanetJson(
          sampleJson(miladiTarihKisa: '2026-09-30'),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PrayerDay.fromDiyanetJson(
          sampleJson(miladiTarihKisa: '30/09/2026'),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PrayerDay.fromDiyanetJson(
          sampleJson(miladiTarihKisa: '31.09.2026'),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PrayerDay.fromDiyanetJson(
          sampleJson(miladiTarihKisa: '29.02.2025'),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PrayerDay.fromDiyanetJson(
          sampleJson()..remove('MiladiTarihKisa'),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('geçersiz MiladiTarihKisa ayı FormatException fırlatır', () {
      expect(
        () => PrayerDay.fromDiyanetJson(
          sampleJson(miladiTarihKisa: '15.13.2026'),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PrayerDay.fromDiyanetJson(
          sampleJson(miladiTarihKisa: '15.00.2026'),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('ofset metin veya sayı olmadığında FormatException fırlatır', () {
      expect(
        () => PrayerDay.fromDiyanetJson(
          sampleJson(greenwichOrtalamaZamani: '3'),
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('GreenwichOrtalamaZamani'),
          ),
        ),
      );
      expect(
        () => PrayerDay.fromDiyanetJson(
          sampleJson()..remove('GreenwichOrtalamaZamani'),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PrayerDay.fromDiyanetJson(
          sampleJson(greenwichOrtalamaZamani: double.nan),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PrayerDay.fromDiyanetJson(
          sampleJson(greenwichOrtalamaZamani: double.infinity),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('eksik veya geçersiz HicriTarihUzun FormatException fırlatır', () {
      expect(
        () => PrayerDay.fromDiyanetJson(sampleJson()..remove('HicriTarihUzun')),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PrayerDay.fromDiyanetJson(sampleJson(hicriTarihUzun: '')),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PrayerDay.fromDiyanetJson(sampleJson(hicriTarihUzun: 12345)),
        throwsA(isA<FormatException>()),
      );
    });

    test('geçersiz KibleSaati FormatException fırlatır', () {
      expect(
        () => PrayerDay.fromDiyanetJson(sampleJson(kibleSaati: 1132)),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PrayerDay.fromDiyanetJson(sampleJson(kibleSaati: '25:61')),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'listFromDiyanetJson içinde Map olmayan öğe FormatException fırlatır',
      () {
        expect(
          () => PrayerDay.listFromDiyanetJson([123]),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => PrayerDay.listFromDiyanetJson(['geçersiz']),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => PrayerDay.listFromDiyanetJson([null]),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test(
      'listFromDiyanetJson içinde string anahtarlı olmayan Map hata verir',
      () {
        expect(
          () => PrayerDay.listFromDiyanetJson([
            {1: 'geçersiz anahtar'},
          ]),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('listFromDiyanetJson dinamik tipli Map nesnelerini çözer', () {
      final dynamicMap = <dynamic, dynamic>{
        'MiladiTarihKisa': '30.09.2026',
        'GreenwichOrtalamaZamani': 3.0,
        'HicriTarihUzun': '19 Rebiulahir 1448',
        'Imsak': '05:28',
        'Gunes': '06:52',
        'Ogle': '12:59',
        'Ikindi': '16:18',
        'Aksam': '18:56',
        'Yatsi': '20:15',
        'KibleSaati': '11:32',
      };
      final days = PrayerDay.listFromDiyanetJson([dynamicMap]);
      expect(days.length, equals(1));
      expect(days.first.date, equals(DateTime.utc(2026, 9, 30)));
    });
  });

  group('PrayerDay Equatable ve timeOf testleri', () {
    test('aynı JSON verisinden çözümlenen iki nesne eşittir', () {
      final day1 = PrayerDay.fromDiyanetJson(sampleJson());
      final day2 = PrayerDay.fromDiyanetJson(sampleJson());

      expect(day1, equals(day2));
      expect(day1.hashCode, equals(day2.hashCode));
    });

    test('bir vakti farklı olan nesneler eşit değildir', () {
      final day1 = PrayerDay.fromDiyanetJson(sampleJson());
      final dayDiffPrayer = PrayerDay.fromDiyanetJson(
        sampleJson(imsak: '05:30'),
      );

      expect(day1, isNot(equals(dayDiffPrayer)));
    });

    test('tarihi farklı olan nesneler eşit değildir', () {
      final day1 = PrayerDay.fromDiyanetJson(sampleJson());
      final dayDiffDate = PrayerDay.fromDiyanetJson(
        sampleJson(miladiTarihKisa: '01.10.2026'),
      );

      expect(day1, isNot(equals(dayDiffDate)));
    });

    test('ofseti farklı olan nesneler eşit değildir', () {
      final day1 = PrayerDay.fromDiyanetJson(sampleJson());
      final dayDiffOffset = PrayerDay.fromDiyanetJson(
        sampleJson(greenwichOrtalamaZamani: 2.0),
      );

      expect(day1, isNot(equals(dayDiffOffset)));
    });

    test('hicri tarihi farklı olan nesneler eşit değildir', () {
      final day1 = PrayerDay.fromDiyanetJson(sampleJson());
      final dayDiffHijri = PrayerDay.fromDiyanetJson(
        sampleJson(hicriTarihUzun: '20 Rebiulahir 1448'),
      );

      expect(day1, isNot(equals(dayDiffHijri)));
    });

    test('kıble saati farklı olan nesneler eşit değildir', () {
      final day1 = PrayerDay.fromDiyanetJson(sampleJson());
      final dayNoQibla = PrayerDay.fromDiyanetJson(
        sampleJson()..remove('KibleSaati'),
      );

      expect(day1, isNot(equals(dayNoQibla)));
    });

    test('timeOf metodu bütün vakitler için doğru değeri döner', () {
      final day = PrayerDay.fromDiyanetJson(sampleJson());
      for (final prayer in Prayer.values) {
        expect(day.timeOf(prayer), equals(day.times[prayer]));
      }
    });
  });
}
