// time_format saf fonksiyonları için birim testleri.

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vakit/prayer_times/widgets/time_format.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
  });

  group('formatClock', () {
    test('standart UTC saatini ofsetle doğru biçimler', () {
      final utc = DateTime.utc(2026, 9, 30, 15, 56);
      expect(formatClock(utc, const Duration(hours: 3)), equals('18:56'));
    });

    test('gece yarısını aşan ofset sonraki güne geçer', () {
      final utc = DateTime.utc(2026, 9, 30, 22, 30);
      expect(formatClock(utc, const Duration(hours: 3)), equals('01:30'));
    });

    test('tek basamaklı saat ve dakikayı sıfırla doldurur', () {
      final utc = DateTime.utc(2026, 9, 30, 1, 5);
      expect(formatClock(utc, const Duration(hours: 3)), equals('04:05'));
    });

    test('yerel DateTime verildiğinde önce UTC çevrimi yapar', () {
      final local = DateTime(2026, 9, 30, 12);
      final expected = formatClock(local.toUtc(), const Duration(hours: 3));
      expect(formatClock(local, const Duration(hours: 3)), equals(expected));
    });
  });

  group('formatCountdown', () {
    test('saat ve dakikayı SS:dd:ss formatında üretir', () {
      const d = Duration(hours: 2, minutes: 59);
      expect(formatCountdown(d), equals('02:59:00'));
    });

    test('yalnızca saniye içeren süreyi biçimler', () {
      const d = Duration(seconds: 45);
      expect(formatCountdown(d), equals('00:00:45'));
    });

    test('negatif süre 00:00:00 döner', () {
      const d = Duration(seconds: -10);
      expect(formatCountdown(d), equals('00:00:00'));
    });

    test('sıfır süre 00:00:00 döner', () {
      expect(formatCountdown(Duration.zero), equals('00:00:00'));
    });

    test('24 saati aşan süre saat hanesini büyütür', () {
      const d = Duration(hours: 25);
      expect(formatCountdown(d), equals('25:00:00'));
    });

    test('saat, dakika ve saniye içeren süreyi doğru biçimler', () {
      const d = Duration(hours: 1, minutes: 23, seconds: 45);
      expect(formatCountdown(d), equals('01:23:45'));
    });
  });

  group('formatLongDate', () {
    test('UTC tarihini d MMMM y EEEE formatında Türkçe biçimler', () {
      final date = DateTime.utc(2026, 9, 30);
      expect(formatLongDate(date), equals('30 Eylül 2026 Çarşamba'));
    });

    test('saat bilgisi içeren UTC tarihinin yalnız takvim gününü alır', () {
      final date = DateTime.utc(2026, 9, 30, 23, 45);
      expect(formatLongDate(date), equals('30 Eylül 2026 Çarşamba'));
    });

    test('farklı bir gün ve ayı doğru biçimler', () {
      final date = DateTime.utc(2026, 10);
      expect(formatLongDate(date), equals('1 Ekim 2026 Perşembe'));
    });
  });
}
