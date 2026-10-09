// Diyanet API'sinden alınan günlük namaz vakitlerini mutlak UTC zamanlarıyla
// temsil eden veri modeli.

import 'package:equatable/equatable.dart';
import 'package:vakit/prayer_times/models/prayer.dart';

class PrayerDay extends Equatable {
  const PrayerDay({
    required this.date,
    required this.utcOffset,
    required this.times,
    required this.hijriDate,
    this.qiblaTime,
  });

  factory PrayerDay.fromDiyanetJson(Map<String, dynamic> json) {
    final rawDate = json['MiladiTarihKisa'];
    if (rawDate is! String) {
      throw const FormatException('Eksik veya geçersiz MiladiTarihKisa');
    }
    final dateMatch = RegExp(
      r'^(\d{2})\.(\d{2})\.(\d{4})$',
    ).firstMatch(rawDate);
    if (dateMatch == null) {
      throw FormatException(
        'Geçersiz MiladiTarihKisa biçimi: "$rawDate" '
        '(gg.aa.yyyy bekleniyor)',
      );
    }
    final day = int.parse(dateMatch.group(1)!);
    final month = int.parse(dateMatch.group(2)!);
    final year = int.parse(dateMatch.group(3)!);
    if (month < 1 || month > 12) {
      throw FormatException('Geçersiz MiladiTarihKisa ayı: $month');
    }
    final date = DateTime.utc(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw FormatException(
        'Geçersiz MiladiTarihKisa takvim günü: $rawDate',
      );
    }

    final rawOffset = json['GreenwichOrtalamaZamani'];
    if (rawOffset == null || rawOffset is! num) {
      throw FormatException(
        'Eksik veya geçersiz GreenwichOrtalamaZamani: $rawOffset',
      );
    }
    final offsetHours = rawOffset.toDouble();
    if (offsetHours.isNaN || offsetHours.isInfinite) {
      throw FormatException(
        'Geçersiz GreenwichOrtalamaZamani değeri: $rawOffset',
      );
    }
    final offsetMinutes = (offsetHours * 60).round();
    final utcOffset = Duration(minutes: offsetMinutes);

    final rawHijri = json['HicriTarihUzun'];
    if (rawHijri is! String || rawHijri.isEmpty) {
      throw const FormatException('Eksik veya geçersiz HicriTarihUzun');
    }

    final times = <Prayer, DateTime>{
      Prayer.imsak: _parsePrayerTime(
        rawTime: json['Imsak'],
        fieldName: 'Imsak',
        year: year,
        month: month,
        day: day,
        utcOffset: utcOffset,
      ),
      Prayer.gunes: _parsePrayerTime(
        rawTime: json['Gunes'],
        fieldName: 'Gunes',
        year: year,
        month: month,
        day: day,
        utcOffset: utcOffset,
      ),
      Prayer.ogle: _parsePrayerTime(
        rawTime: json['Ogle'],
        fieldName: 'Ogle',
        year: year,
        month: month,
        day: day,
        utcOffset: utcOffset,
      ),
      Prayer.ikindi: _parsePrayerTime(
        rawTime: json['Ikindi'],
        fieldName: 'Ikindi',
        year: year,
        month: month,
        day: day,
        utcOffset: utcOffset,
      ),
      Prayer.aksam: _parsePrayerTime(
        rawTime: json['Aksam'],
        fieldName: 'Aksam',
        year: year,
        month: month,
        day: day,
        utcOffset: utcOffset,
      ),
      Prayer.yatsi: _parsePrayerTime(
        rawTime: json['Yatsi'],
        fieldName: 'Yatsi',
        year: year,
        month: month,
        day: day,
        utcOffset: utcOffset,
      ),
    };

    DateTime? qiblaTime;
    final rawQibla = json['KibleSaati'];
    if (rawQibla != null) {
      if (rawQibla is! String) {
        throw FormatException('KibleSaati metin olmalı: $rawQibla');
      }
      final trimmed = rawQibla.trim();
      if (trimmed.isNotEmpty) {
        qiblaTime = _parsePrayerTime(
          rawTime: trimmed,
          fieldName: 'KibleSaati',
          year: year,
          month: month,
          day: day,
          utcOffset: utcOffset,
        );
      }
    }

    return PrayerDay(
      date: date,
      utcOffset: utcOffset,
      times: Map.unmodifiable(times),
      hijriDate: rawHijri,
      qiblaTime: qiblaTime,
    );
  }

  final DateTime date;
  final Duration utcOffset;
  final Map<Prayer, DateTime> times;
  final String hijriDate;
  final DateTime? qiblaTime;

  static List<PrayerDay> listFromDiyanetJson(List<dynamic> json) {
    final list = <PrayerDay>[];
    for (var i = 0; i < json.length; i++) {
      final item = json[i];
      if (item is! Map<String, dynamic>) {
        if (item is Map) {
          final stringKeyMap = <String, dynamic>{};
          for (final entry in item.entries) {
            if (entry.key is! String) {
              throw FormatException(
                'Map anahtarı String olmalı (indeks: $i, '
                'anahtar: ${entry.key})',
              );
            }
            stringKeyMap[entry.key as String] = entry.value;
          }
          list.add(PrayerDay.fromDiyanetJson(stringKeyMap));
          continue;
        }
        throw FormatException(
          'Diyanet vakit listesi öğesi Map olmalı (indeks: $i)',
        );
      }
      list.add(PrayerDay.fromDiyanetJson(item));
    }
    return List.unmodifiable(list);
  }

  DateTime timeOf(Prayer prayer) => times[prayer]!;

  @override
  List<Object?> get props => [
    date,
    utcOffset,
    times,
    hijriDate,
    qiblaTime,
  ];

  static DateTime _parsePrayerTime({
    required dynamic rawTime,
    required String fieldName,
    required int year,
    required int month,
    required int day,
    required Duration utcOffset,
  }) {
    if (rawTime is! String) {
      throw FormatException(
        'Eksik veya geçersiz $fieldName vakti: $rawTime',
      );
    }
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(rawTime);
    if (match == null) {
      throw FormatException(
        'Geçersiz $fieldName biçimi: "$rawTime" (SS:dd bekleniyor)',
      );
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) {
      throw FormatException('Aralık dışı $fieldName saati: "$rawTime"');
    }
    return DateTime.utc(year, month, day, hour, minute).subtract(utcOffset);
  }
}
