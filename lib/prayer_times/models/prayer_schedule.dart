// Namaz vakitleri çizelgesi, anlık durum, geri sayım ve gün dönümü modeli.

import 'package:equatable/equatable.dart';
import 'package:vakit/prayer_times/models/prayer.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';

/// Belirli bir günün belirli bir namaz vaktini temsil eden mutlak zaman anı.
class PrayerMoment extends Equatable {
  const PrayerMoment({
    required this.prayer,
    required this.time,
    required this.date,
  });

  final Prayer prayer;
  final DateTime time;
  final DateTime date;

  @override
  List<Object?> get props => [prayer, time, date];
}

/// Çizelgenin belirli bir andaki durumunu temsil eden model.
class ScheduleStatus extends Equatable {
  const ScheduleStatus({
    required this.daysRemaining,
    this.current,
    this.next,
    this.remaining,
    this.progress,
    this.today,
  });

  final PrayerMoment? current;
  final PrayerMoment? next;
  final Duration? remaining;
  final double? progress;
  final PrayerDay? today;
  final int daysRemaining;

  bool get isExhausted => next == null;

  @override
  List<Object?> get props => [
    current,
    next,
    remaining,
    progress,
    today,
    daysRemaining,
  ];
}

/// Günlük vakit listesini yöneten ve verilen andaki durumu hesaplayan sınıf.
class PrayerSchedule {
  PrayerSchedule(List<PrayerDay> days) : this._(_processDays(days));

  PrayerSchedule._(this.days) : moments = _createMoments(days);

  final List<PrayerDay> days;
  final List<PrayerMoment> moments;

  ScheduleStatus statusAt(DateTime now) {
    final utcNow = now.toUtc();
    if (days.isEmpty) {
      return const ScheduleStatus(daysRemaining: 0);
    }

    PrayerMoment? current;
    PrayerMoment? next;
    for (final moment in moments) {
      if (!moment.time.isAfter(utcNow)) {
        current = moment;
      } else {
        next = moment;
        break;
      }
    }

    final remaining = next?.time.difference(utcNow);

    double? progress;
    if (current != null && next != null) {
      final totalMicroseconds = next.time
          .difference(current.time)
          .inMicroseconds;
      final elapsedMicroseconds = utcNow
          .difference(current.time)
          .inMicroseconds;
      final ratio = elapsedMicroseconds / totalMicroseconds;
      progress = ratio.clamp(0, 1).toDouble();
    }

    PrayerDay? today;
    for (final day in days) {
      final dayStartUtc = day.date.subtract(day.utcOffset);
      final dayEndUtc = day.date
          .add(const Duration(days: 1))
          .subtract(day.utcOffset);
      if (!utcNow.isBefore(dayStartUtc) && utcNow.isBefore(dayEndUtc)) {
        today = day;
        break;
      }
    }

    final localDate = _localCalendarDate(utcNow, today);
    final daysRemaining = days.where((d) {
      final dNorm = _normalizeDate(d.date);
      return !dNorm.isBefore(localDate);
    }).length;

    return ScheduleStatus(
      current: current,
      next: next,
      remaining: remaining,
      progress: progress,
      today: today,
      daysRemaining: daysRemaining,
    );
  }

  DateTime _localCalendarDate(DateTime utcNow, PrayerDay? today) {
    if (today != null) {
      return _normalizeDate(today.date);
    }
    final Duration offset;
    final firstDayStart = days.first.date.subtract(days.first.utcOffset);
    if (utcNow.isBefore(firstDayStart)) {
      offset = days.first.utcOffset;
    } else {
      offset = days.last.utcOffset;
    }
    final localDateTime = utcNow.add(offset);
    return DateTime.utc(
      localDateTime.year,
      localDateTime.month,
      localDateTime.day,
    );
  }

  static DateTime _normalizeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  static List<PrayerDay> _processDays(List<PrayerDay> days) {
    final byDate = <DateTime, PrayerDay>{};
    for (final day in days) {
      byDate[_normalizeDate(day.date)] = day;
    }
    final sorted = byDate.values.toList()
      ..sort(
        (a, b) => _normalizeDate(a.date).compareTo(_normalizeDate(b.date)),
      );
    return List.unmodifiable(sorted);
  }

  static List<PrayerMoment> _createMoments(List<PrayerDay> days) {
    final allMoments = <PrayerMoment>[];
    for (final day in days) {
      for (final prayer in Prayer.values) {
        allMoments.add(
          PrayerMoment(
            prayer: prayer,
            time: day.timeOf(prayer),
            date: day.date,
          ),
        );
      }
    }
    return List.unmodifiable(allMoments);
  }
}
