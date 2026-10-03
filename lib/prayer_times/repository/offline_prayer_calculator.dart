// adhan_dart paketi ve Türkiye metoduyla çevrimdışı yedek namaz vakti
// hesaplayıcısı.

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:vakit/prayer_times/models/prayer.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';

/// Diyanet servisine erişilemediğinde ve önbellek tükendiğinde cihaz üzerinde
/// adhan_dart kütüphanesini ve Diyanet parametrelerini kullanarak namaz
/// vakti hesaplayan sınıf.
class OfflinePrayerCalculator {
  const OfflinePrayerCalculator();

  /// Verilen koordinatlar için [from] tarihinden başlayarak [days] günlük
  /// namaz vakitlerini hesaplar.
  ///
  /// [from] parametresinin yalnızca yıl, ay ve gün bilgisi kullanılır.
  /// [days] 1'den küçükse, [latitude] [-90, 90] veya [longitude]
  /// [-180, 180] aralığı dışındaysa [ArgumentError] fırlatılır.
  List<PrayerDay> calculate({
    required double latitude,
    required double longitude,
    required DateTime from,
    int days = 30,
    Duration utcOffset = const Duration(hours: 3),
  }) {
    if (days < 1) {
      throw ArgumentError.value(
        days,
        'days',
        'Gün sayısı en az 1 olmalıdır.',
      );
    }
    if (latitude.isNaN || latitude < -90 || latitude > 90) {
      throw ArgumentError.value(
        latitude,
        'latitude',
        'Enlem [-90, 90] aralığında olmalıdır.',
      );
    }
    if (longitude.isNaN || longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'Boylam [-180, 180] aralığında olmalıdır.',
      );
    }

    final startDate = DateTime.utc(from.year, from.month, from.day);
    final coordinates = adhan.Coordinates(latitude, longitude);
    final parameters = adhan.CalculationMethodParameters.turkiye();

    final result = <PrayerDay>[];
    for (var i = 0; i < days; i++) {
      final date = DateTime.utc(
        startDate.year,
        startDate.month,
        startDate.day + i,
      );
      final prayerTimes = adhan.PrayerTimes(
        date: date,
        coordinates: coordinates,
        calculationParameters: parameters,
      );
      final times = <Prayer, DateTime>{
        Prayer.imsak: prayerTimes.fajr.toUtc(),
        Prayer.gunes: prayerTimes.sunrise.toUtc(),
        Prayer.ogle: prayerTimes.dhuhr.toUtc(),
        Prayer.ikindi: prayerTimes.asr.toUtc(),
        Prayer.aksam: prayerTimes.maghrib.toUtc(),
        Prayer.yatsi: prayerTimes.isha.toUtc(),
      };
      result.add(
        PrayerDay(
          date: date,
          utcOffset: utcOffset,
          times: Map.unmodifiable(times),
          hijriDate: '',
        ),
      );
    }

    return List.unmodifiable(result);
  }
}
