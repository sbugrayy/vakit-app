// OfflinePrayerCalculator ve adhan_dart hesaplama testleri.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/prayer_times/models/prayer.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';
import 'package:vakit/prayer_times/repository/offline_prayer_calculator.dart';

void main() {
  const fixtures = [
    (
      id: '9541',
      city: 'İstanbul',
      latitude: 41.0082,
      longitude: 28.9784,
    ),
    (
      id: '9206',
      city: 'Ankara',
      latitude: 39.9334,
      longitude: 32.8597,
    ),
    (
      id: '9930',
      city: 'Van',
      latitude: 38.5012,
      longitude: 43.3730,
    ),
  ];

  group('OfflinePrayerCalculator Diyanet fixture karşılaştırmaları', () {
    for (final fixture in fixtures) {
      test(
        '${fixture.city} (${fixture.id}) 32 günün tamamında '
        'Diyanet ile fark en fazla 2 dakikadır',
        () {
          const calculator = OfflinePrayerCalculator();
          final file = File(
            'test/fixtures/diyanet/vakitler_${fixture.id}.json',
          );
          final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;
          final diyanetDays = PrayerDay.listFromDiyanetJson(json);

          expect(diyanetDays.length, equals(32));

          final calculatedDays = calculator.calculate(
            latitude: fixture.latitude,
            longitude: fixture.longitude,
            from: diyanetDays.first.date,
            days: diyanetDays.length,
            utcOffset: diyanetDays.first.utcOffset,
          );

          expect(calculatedDays.length, equals(diyanetDays.length));

          for (var i = 0; i < diyanetDays.length; i++) {
            final diyanetDay = diyanetDays[i];
            final calcDay = calculatedDays[i];

            expect(calcDay.date, equals(diyanetDay.date));

            for (final prayer in Prayer.values) {
              final diyanetTime = diyanetDay.timeOf(prayer);
              final calcTime = calcDay.timeOf(prayer);
              final diffInMinutes = calcTime
                  .difference(diyanetTime)
                  .inMinutes
                  .abs();

              expect(
                diffInMinutes,
                lessThanOrEqualTo(2),
                reason:
                    'Günü: ${diyanetDay.date.toIso8601String()}, '
                    'vakti: ${prayer.name} (${prayer.label}), '
                    'fark: $diffInMinutes dk (hesap: $calcTime, '
                    'Diyanet: $diyanetTime)',
              );
            }
          }
        },
      );
    }
  });

  group('OfflinePrayerCalculator gün sayısı ve tarih aralığı', () {
    const calculator = OfflinePrayerCalculator();

    test('varsayılan olarak 30 gün üretir ve tarihler art ardadır', () {
      final days = calculator.calculate(
        latitude: 41.0082,
        longitude: 28.9784,
        from: DateTime.utc(2026, 9, 30),
      );

      expect(days.length, equals(30));
      for (var i = 0; i < days.length - 1; i++) {
        expect(
          days[i + 1].date,
          equals(days[i].date.add(const Duration(days: 1))),
        );
      }
    });

    test(
      'ay ve yıl geçişinde tarihler art arda doğru hesaplanır',
      () {
        final days = calculator.calculate(
          latitude: 41.0082,
          longitude: 28.9784,
          from: DateTime.utc(2026, 12, 20),
          days: 15,
        );

        expect(days.length, equals(15));
        expect(days.first.date, equals(DateTime.utc(2026, 12, 20)));
        expect(days.last.date, equals(DateTime.utc(2027, 1, 3)));
        for (var i = 0; i < days.length - 1; i++) {
          expect(
            days[i + 1].date,
            equals(days[i].date.add(const Duration(days: 1))),
          );
        }
      },
    );

    test('days: 1 sınır değeri ile tek gün hesaplanır', () {
      final days = calculator.calculate(
        latitude: 41.0082,
        longitude: 28.9784,
        from: DateTime.utc(2026, 9, 30),
        days: 1,
      );

      expect(days.length, equals(1));
      expect(days.first.date, equals(DateTime.utc(2026, 9, 30)));
    });
  });

  group('OfflinePrayerCalculator vakit sırası ve alanlar', () {
    const calculator = OfflinePrayerCalculator();

    test(
      'her günde 6 vakit kesin artan sırada ve PrayerDay alanları doğru',
      () {
        const customOffset = Duration(hours: 4);
        final days = calculator.calculate(
          latitude: 41.0082,
          longitude: 28.9784,
          from: DateTime.utc(2026, 10),
          days: 7,
          utcOffset: customOffset,
        );

        for (final day in days) {
          expect(day.hijriDate, isEmpty);
          expect(day.qiblaTime, isNull);
          expect(day.utcOffset, equals(customOffset));

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

    test(
      'from saat ve dakika içerse de başlangıç gününün tarihi değişmez',
      () {
        final daysFromMidnight = calculator.calculate(
          latitude: 41.0082,
          longitude: 28.9784,
          from: DateTime.utc(2026, 9, 30),
          days: 3,
        );
        final daysFromLateNight = calculator.calculate(
          latitude: 41.0082,
          longitude: 28.9784,
          from: DateTime.utc(2026, 9, 30, 23, 59, 59),
          days: 3,
        );

        expect(
          daysFromLateNight.first.date,
          equals(DateTime.utc(2026, 9, 30)),
        );
        expect(daysFromLateNight, equals(daysFromMidnight));
      },
    );
  });

  group('OfflinePrayerCalculator ArgumentError doğrulamaları', () {
    const calculator = OfflinePrayerCalculator();
    final validFrom = DateTime.utc(2026, 9, 30);

    test('days 1 den küçük olduğunda ArgumentError fırlatır', () {
      expect(
        () => calculator.calculate(
          latitude: 41,
          longitude: 28.9,
          from: validFrom,
          days: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => calculator.calculate(
          latitude: 41,
          longitude: 28.9,
          from: validFrom,
          days: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'enlem [-90, 90] aralığı dışında olduğunda ArgumentError fırlatır',
      () {
        expect(
          () => calculator.calculate(
            latitude: 90.1,
            longitude: 28.9,
            from: validFrom,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => calculator.calculate(
            latitude: -90.1,
            longitude: 28.9,
            from: validFrom,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => calculator.calculate(
            latitude: double.nan,
            longitude: 28.9,
            from: validFrom,
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'boylam [-180, 180] aralığı dışında olduğunda ArgumentError fırlatır',
      () {
        expect(
          () => calculator.calculate(
            latitude: 41,
            longitude: 180.1,
            from: validFrom,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => calculator.calculate(
            latitude: 41,
            longitude: -180.1,
            from: validFrom,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => calculator.calculate(
            latitude: 41,
            longitude: double.nan,
            from: validFrom,
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });
}
