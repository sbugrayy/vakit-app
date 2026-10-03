// PrayerSchedule, PrayerMoment ve ScheduleStatus model testleri.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/prayer_times/models/prayer.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';
import 'package:vakit/prayer_times/models/prayer_schedule.dart';

void main() {
  late List<PrayerDay> days;
  late PrayerSchedule schedule;

  setUpAll(() {
    final file = File('test/fixtures/diyanet/vakitler_9541.json');
    final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    days = PrayerDay.listFromDiyanetJson(json);
    schedule = PrayerSchedule(days);
  });

  group('PrayerSchedule senaryo testleri (vakitler_9541.json)', () {
    test(
      'Senaryo 1: 2026-09-30T07:00Z yerel 10:00 Güneş sonrası Öğle öncesi',
      () {
        final now = DateTime.utc(2026, 9, 30, 7);
        final status = schedule.statusAt(now);

        expect(status.current?.prayer, equals(Prayer.gunes));
        expect(
          status.current?.time,
          equals(DateTime.utc(2026, 9, 30, 3, 52)),
        );
        expect(
          status.current?.date,
          equals(DateTime.utc(2026, 9, 30)),
        );
        expect(status.next?.prayer, equals(Prayer.ogle));
        expect(
          status.next?.time,
          equals(DateTime.utc(2026, 9, 30, 9, 59)),
        );
        expect(
          status.next?.date,
          equals(DateTime.utc(2026, 9, 30)),
        );
        expect(
          status.remaining,
          equals(const Duration(hours: 2, minutes: 59)),
        );
        expect(status.today?.date, equals(DateTime.utc(2026, 9, 30)));
        expect(status.daysRemaining, equals(32));
        expect(status.isExhausted, isFalse);
      },
    );

    test('Senaryo 2: 2026-09-30T09:59:00Z tam Öğle vakti', () {
      final now = DateTime.utc(2026, 9, 30, 9, 59);
      final status = schedule.statusAt(now);

      expect(status.current?.prayer, equals(Prayer.ogle));
      expect(status.next?.prayer, equals(Prayer.ikindi));
      expect(
        status.remaining,
        equals(const Duration(hours: 3, minutes: 19)),
      );
    });

    test('Senaryo 3: 2026-09-30T20:00Z yerel 23:00 Yatsı sonrası', () {
      final now = DateTime.utc(2026, 9, 30, 20);
      final status = schedule.statusAt(now);

      expect(status.current?.prayer, equals(Prayer.yatsi));
      expect(
        status.current?.date,
        equals(DateTime.utc(2026, 9, 30)),
      );
      expect(status.next?.prayer, equals(Prayer.imsak));
      expect(
        status.next?.time,
        equals(DateTime.utc(2026, 10, 1, 2, 29)),
      );
      expect(
        status.next?.date,
        equals(DateTime.utc(2026, 10)),
      );
      expect(
        status.remaining,
        equals(const Duration(hours: 6, minutes: 29)),
      );
      expect(status.today?.date, equals(DateTime.utc(2026, 9, 30)));
    });

    test('Senaryo 4: 2026-09-30T21:30Z yerel 01.10 00:30 gün dönümü', () {
      final now = DateTime.utc(2026, 9, 30, 21, 30);
      final status = schedule.statusAt(now);

      expect(status.today?.date, equals(DateTime.utc(2026, 10)));
      expect(status.daysRemaining, equals(31));
      expect(status.current?.prayer, equals(Prayer.yatsi));
      expect(
        status.current?.date,
        equals(DateTime.utc(2026, 9, 30)),
      );
      expect(status.next?.prayer, equals(Prayer.imsak));
      expect(
        status.next?.time,
        equals(DateTime.utc(2026, 10, 1, 2, 29)),
      );
      expect(
        status.remaining,
        equals(const Duration(hours: 4, minutes: 59)),
      );
    });

    test('Senaryo 5: 2026-09-29T22:00Z ilk İmsaktan önce', () {
      final now = DateTime.utc(2026, 9, 29, 22);
      final status = schedule.statusAt(now);

      expect(status.current, isNull);
      expect(status.next?.prayer, equals(Prayer.imsak));
      expect(
        status.next?.time,
        equals(DateTime.utc(2026, 9, 30, 2, 28)),
      );
      expect(
        status.remaining,
        equals(const Duration(hours: 4, minutes: 28)),
      );
      expect(status.progress, isNull);
      expect(status.today?.date, equals(DateTime.utc(2026, 9, 30)));
    });

    test('Senaryo 6: 2026-10-31T20:30Z son Yatsı sonrası', () {
      final now = DateTime.utc(2026, 10, 31, 20, 30);
      final status = schedule.statusAt(now);

      expect(status.current?.prayer, equals(Prayer.yatsi));
      expect(
        status.current?.date,
        equals(DateTime.utc(2026, 10, 31)),
      );
      expect(status.next, isNull);
      expect(status.isExhausted, isTrue);
      expect(status.remaining, isNull);
      expect(status.progress, isNull);
      expect(status.today?.date, equals(DateTime.utc(2026, 10, 31)));
      expect(status.daysRemaining, equals(1));
    });

    test('Senaryo 7: 2026-09-30T11:38:30Z tam orta ilerleme 0.5', () {
      final now = DateTime.utc(2026, 9, 30, 11, 38, 30);
      final status = schedule.statusAt(now);

      expect(status.progress, isNotNull);
      expect(status.progress, closeTo(0.5, 0.001));
    });

    test('Senaryo 8: 2026-10-29T07:00Z kalan gün 3', () {
      final now = DateTime.utc(2026, 10, 29, 7);
      final status = schedule.statusAt(now);

      expect(status.daysRemaining, equals(3));
    });

    test(
      'Senaryo 9: toLocal ve UTC hali aynı ScheduleStatus sonucunu verir',
      () {
        final utcNow = DateTime.utc(2026, 9, 30, 7);
        final localNow = utcNow.toLocal();

        final statusUtc = schedule.statusAt(utcNow);
        final statusLocal = schedule.statusAt(localNow);

        expect(statusLocal, equals(statusUtc));
      },
    );

    test('Senaryo 10: ters sıralı ve tekrarlı girdi doğru işlenir', () {
      final reversedDays = days.reversed.toList();
      final reversedSchedule = PrayerSchedule(reversedDays);

      final now = DateTime.utc(2026, 9, 30, 7);
      expect(
        reversedSchedule.statusAt(now),
        equals(schedule.statusAt(now)),
      );
      expect(reversedSchedule.days, equals(schedule.days));
      expect(reversedSchedule.moments, equals(schedule.moments));

      final modifiedFirstDay = PrayerDay(
        date: days.first.date,
        utcOffset: days.first.utcOffset,
        times: days.first.times,
        hijriDate: 'Farklı Hicri Tarih',
        qiblaTime: days.first.qiblaTime,
      );
      final withDuplicate = PrayerSchedule([
        ...days,
        modifiedFirstDay,
      ]);
      expect(withDuplicate.days.length, equals(days.length));
      expect(
        withDuplicate.days.first.hijriDate,
        equals('Farklı Hicri Tarih'),
      );
    });

    test('Senaryo 11: boş liste null ve sıfır döner', () {
      final emptySchedule = PrayerSchedule(const []);
      final status = emptySchedule.statusAt(DateTime.utc(2026, 9, 30, 7));

      expect(status.current, isNull);
      expect(status.next, isNull);
      expect(status.remaining, isNull);
      expect(status.progress, isNull);
      expect(status.today, isNull);
      expect(status.daysRemaining, equals(0));
      expect(status.isExhausted, isTrue);
    });
  });

  group('PrayerSchedule sınır ve model ek testleri', () {
    test(
      'ilk günün yerel başlangıcından önce today null ve daysRemaining 32',
      () {
        final now = DateTime.utc(2026, 9, 29, 20);
        final status = schedule.statusAt(now);

        expect(status.today, isNull);
        expect(status.daysRemaining, equals(32));
        expect(status.current, isNull);
        expect(status.next?.prayer, equals(Prayer.imsak));
      },
    );

    test('son günün yerel bitiminden sonra today null ve daysRemaining 0', () {
      final now = DateTime.utc(2026, 11);
      final status = schedule.statusAt(now);

      expect(status.today, isNull);
      expect(status.daysRemaining, equals(0));
      expect(status.current?.prayer, equals(Prayer.yatsi));
      expect(status.next, isNull);
      expect(status.isExhausted, isTrue);
    });

    test('PrayerMoment eşitlik ve props testi', () {
      final moment1 = PrayerMoment(
        prayer: Prayer.imsak,
        time: DateTime.utc(2026, 9, 30, 2, 28),
        date: DateTime.utc(2026, 9, 30),
      );
      final moment2 = PrayerMoment(
        prayer: Prayer.imsak,
        time: DateTime.utc(2026, 9, 30, 2, 28),
        date: DateTime.utc(2026, 9, 30),
      );
      final momentDiffPrayer = PrayerMoment(
        prayer: Prayer.gunes,
        time: DateTime.utc(2026, 9, 30, 2, 28),
        date: DateTime.utc(2026, 9, 30),
      );
      final momentDiffTime = PrayerMoment(
        prayer: Prayer.imsak,
        time: DateTime.utc(2026, 9, 30, 3),
        date: DateTime.utc(2026, 9, 30),
      );
      final momentDiffDate = PrayerMoment(
        prayer: Prayer.imsak,
        time: DateTime.utc(2026, 9, 30, 2, 28),
        date: DateTime.utc(2026, 10),
      );

      expect(moment1, equals(moment2));
      expect(moment1.hashCode, equals(moment2.hashCode));
      expect(moment1, isNot(equals(momentDiffPrayer)));
      expect(moment1, isNot(equals(momentDiffTime)));
      expect(moment1, isNot(equals(momentDiffDate)));
    });

    test('ScheduleStatus eşitlik ve props testi', () {
      const status1 = ScheduleStatus(
        daysRemaining: 10,
        remaining: Duration(hours: 1),
        progress: 0.5,
      );
      const status2 = ScheduleStatus(
        daysRemaining: 10,
        remaining: Duration(hours: 1),
        progress: 0.5,
      );
      const statusDiff = ScheduleStatus(
        daysRemaining: 5,
        remaining: Duration(hours: 1),
        progress: 0.5,
      );

      expect(status1, equals(status2));
      expect(status1.hashCode, equals(status2.hashCode));
      expect(status1, isNot(equals(statusDiff)));
      expect(status1.isExhausted, isTrue);
    });

    test('PrayerSchedule moments listesi kronolojik ve eksiksizdir', () {
      expect(schedule.moments.length, equals(32 * 6));
      for (var i = 0; i < schedule.moments.length - 1; i++) {
        final current = schedule.moments[i];
        final next = schedule.moments[i + 1];
        expect(current.time.isBefore(next.time), isTrue);
      }
    });

    test('days ve moments listeleri değiştirilemez', () {
      expect(
        () => (schedule.days as dynamic).add(days.first),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => (schedule.moments as dynamic).add(schedule.moments.first),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
