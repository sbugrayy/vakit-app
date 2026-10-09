// Namaz vakitlerini Diyanet API, yerel önbellek ve çevrimdışı hesaplama
// hiyerarşisiyle sunan depo sözleşmesi ve varsayılan uygulaması.

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:vakit/location/models/selected_location.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';
import 'package:vakit/prayer_times/models/prayer_schedule.dart';
import 'package:vakit/prayer_times/repository/offline_prayer_calculator.dart';
import 'package:vakit/shared/clock.dart';
import 'package:vakit/shared/diyanet/diyanet_api.dart';
import 'package:vakit/shared/diyanet/diyanet_api_exception.dart';
import 'package:vakit/shared/storage/key_value_store.dart';

enum PrayerDataSource {
  diyanet,
  cache,
  offline,
}

class PrayerTimesResult extends Equatable {
  const PrayerTimesResult({
    required this.days,
    required this.source,
    this.fetchedAt,
  });

  final List<PrayerDay> days;
  final PrayerDataSource source;
  final DateTime? fetchedAt;

  @override
  List<Object?> get props => [days, source, fetchedAt];
}

class PrayerTimesException implements Exception {
  const PrayerTimesException(this.message);

  final String message;

  @override
  String toString() => 'PrayerTimesException: $message';
}

abstract class PrayerTimesRepository {
  const PrayerTimesRepository();

  Future<PrayerTimesResult> load(
    SelectedLocation location, {
    bool forceRefresh = false,
  });
}

class DefaultPrayerTimesRepository implements PrayerTimesRepository {
  DefaultPrayerTimesRepository({
    required this._api,
    required this._store,
    required this._clock,
    this._calculator = const OfflinePrayerCalculator(),
    this._refreshThresholdDays = 10,
  });

  final DiyanetApi _api;
  final KeyValueStore _store;
  final Clock _clock;
  final OfflinePrayerCalculator _calculator;
  final int _refreshThresholdDays;

  static String _daysKey(String districtId) => 'prayer_days_$districtId';
  static String _fetchedAtKey(String districtId) =>
      'prayer_days_${districtId}_fetched_at';

  @override
  Future<PrayerTimesResult> load(
    SelectedLocation location, {
    bool forceRefresh = false,
  }) async {
    List<PrayerDay>? cachedDays;
    DateTime? cachedFetchedAt;

    try {
      final rawDays = await _store.getString(_daysKey(location.districtId));
      if (rawDays != null) {
        final dynamic decoded = jsonDecode(rawDays);
        if (decoded is! List<dynamic>) {
          throw const FormatException('Önbellekteki vakit verisi liste değil.');
        }
        cachedDays = PrayerDay.listFromDiyanetJson(decoded);
      }
    } on FormatException {
      cachedDays = null;
    }

    final rawFetchedAt = await _store.getString(
      _fetchedAtKey(location.districtId),
    );
    if (rawFetchedAt != null) {
      try {
        cachedFetchedAt = DateTime.parse(rawFetchedAt).toUtc();
      } on FormatException {
        cachedFetchedAt = null;
      }
    }

    final remainingDays = cachedDays != null
        ? PrayerSchedule(cachedDays).statusAt(_clock.now()).daysRemaining
        : 0;

    if (!forceRefresh &&
        cachedDays != null &&
        remainingDays >= _refreshThresholdDays) {
      return PrayerTimesResult(
        days: cachedDays,
        source: PrayerDataSource.cache,
        fetchedAt: cachedFetchedAt,
      );
    }

    try {
      final rawJson = await _api.fetchPrayerDaysJson(location.districtId);
      final dynamic decoded = jsonDecode(rawJson);
      final days = PrayerDay.listFromDiyanetJson(decoded as List<dynamic>);
      final nowUtc = _clock.now().toUtc();

      await _store.setString(_daysKey(location.districtId), rawJson);
      await _store.setString(
        _fetchedAtKey(location.districtId),
        nowUtc.toIso8601String(),
      );

      return PrayerTimesResult(
        days: days,
        source: PrayerDataSource.diyanet,
        fetchedAt: nowUtc,
      );
    } on DiyanetApiException {
      if (cachedDays != null && remainingDays > 0) {
        return PrayerTimesResult(
          days: cachedDays,
          source: PrayerDataSource.cache,
          fetchedAt: cachedFetchedAt,
        );
      }

      if (location.hasCoordinates) {
        final turkeyNow = _clock.now().toUtc().add(const Duration(hours: 3));
        final turkeyCalendarDay = DateTime.utc(
          turkeyNow.year,
          turkeyNow.month,
          turkeyNow.day,
        );
        final offlineDays = _calculator.calculate(
          latitude: location.latitude!,
          longitude: location.longitude!,
          from: turkeyCalendarDay,
        );

        return PrayerTimesResult(
          days: offlineDays,
          source: PrayerDataSource.offline,
        );
      }

      throw const PrayerTimesException(
        'Vakitler alınamadı: internet bağlantısı gerekiyor',
      );
    }
  }
}
