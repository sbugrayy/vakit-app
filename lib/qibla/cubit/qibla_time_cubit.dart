// Kıble saati durum yönetimi ve Diyanet verisinden kıble anını yükleme Cubit'i.

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/prayer_times/models/prayer_schedule.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';
import 'package:vakit/shared/clock.dart';

class QiblaTimeState extends Equatable {
  const QiblaTimeState({
    this.time,
    this.utcOffset,
    this.loaded = false,
  });

  final DateTime? time;
  final Duration? utcOffset;
  final bool loaded;

  @override
  List<Object?> get props => [time, utcOffset, loaded];
}

class QiblaTimeCubit extends Cubit<QiblaTimeState> {
  QiblaTimeCubit({
    required this._locationStore,
    required this._repository,
    required this._clock,
  }) : super(const QiblaTimeState());

  final LocationStore _locationStore;
  final PrayerTimesRepository _repository;
  final Clock _clock;

  Future<void> load() async {
    try {
      final location = await _locationStore.load();
      if (isClosed) {
        return;
      }
      if (location == null) {
        emit(const QiblaTimeState(loaded: true));
        return;
      }

      final result = await _repository.load(location);
      if (isClosed) {
        return;
      }

      final today = PrayerSchedule(result.days).statusAt(_clock.now()).today;
      final qiblaTime = today?.qiblaTime;
      if (today == null || qiblaTime == null) {
        emit(const QiblaTimeState(loaded: true));
        return;
      }

      emit(
        QiblaTimeState(
          time: qiblaTime,
          utcOffset: today.utcOffset,
          loaded: true,
        ),
      );
    } on Exception {
      if (isClosed) {
        return;
      }
      emit(const QiblaTimeState(loaded: true));
    }
  }
}
