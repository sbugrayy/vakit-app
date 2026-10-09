// Aylık namaz vakitleri cubit'i ve durum yönetimi.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/prayer_times/cubit/monthly_times_state.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';
import 'package:vakit/prayer_times/models/prayer_schedule.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';
import 'package:vakit/shared/clock.dart';

class MonthlyTimesCubit extends Cubit<MonthlyTimesState> {
  MonthlyTimesCubit({
    required this._locationStore,
    required this._repository,
    required this._clock,
  }) : super(const MonthlyTimesLoading());

  final LocationStore _locationStore;
  final PrayerTimesRepository _repository;
  final Clock _clock;

  Future<void> load() async {
    // Hata durumundan tekrar denerken yükleniyor durumunu göstermek için.
    if (state is! MonthlyTimesLoading) {
      emit(const MonthlyTimesLoading());
    }

    final location = await _locationStore.load();
    if (isClosed) {
      return;
    }
    if (location == null) {
      emit(const MonthlyTimesNeedsLocation());
      return;
    }

    try {
      final result = await _repository.load(location);
      if (isClosed) {
        return;
      }

      final today = PrayerSchedule(result.days).statusAt(_clock.now()).today;
      final List<PrayerDay> days;
      final int todayIndex;
      if (today != null) {
        days = result.days
            .where((day) => !day.date.isBefore(today.date))
            .toList();
        todayIndex = 0;
      } else {
        days = result.days;
        todayIndex = -1;
      }

      emit(
        MonthlyTimesLoaded(
          location: location,
          days: days,
          todayIndex: todayIndex,
          source: result.source,
        ),
      );
    } on Exception {
      if (isClosed) {
        return;
      }
      emit(const MonthlyTimesError('Vakitler yüklenemedi.'));
    }
  }
}
