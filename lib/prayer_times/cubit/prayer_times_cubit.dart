// Namaz vakitleri cubit'i, durum yönetimi ve saniyelik sayaç mekanizması.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/notifications/repository/notification_bridge.dart';
import 'package:vakit/prayer_times/cubit/prayer_times_state.dart';
import 'package:vakit/prayer_times/models/prayer_schedule.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';
import 'package:vakit/shared/clock.dart';

class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit({
    required this._locationStore,
    required this._repository,
    required this._notificationBridge,
    required this._clock,
    this._tick = const Duration(seconds: 1),
  }) : super(const PrayerTimesInitial());

  final LocationStore _locationStore;
  final PrayerTimesRepository _repository;
  final NotificationBridge _notificationBridge;
  final Clock _clock;
  final Duration _tick;

  Timer? _timer;

  Future<void> load({bool forceRefresh = false}) async {
    _timer?.cancel();
    emit(const PrayerTimesLoading());

    final location = await _locationStore.load();
    if (isClosed) {
      return;
    }
    if (location == null) {
      emit(const PrayerTimesNeedsLocation());
      return;
    }

    try {
      final result = await _repository.load(
        location,
        forceRefresh: forceRefresh,
      );
      if (isClosed) {
        return;
      }
      final status = PrayerSchedule(result.days).statusAt(_clock.now());
      emit(
        PrayerTimesLoaded(
          location: location,
          result: result,
          status: status,
        ),
      );
      _startTimer();

      try {
        await _notificationBridge.sync(
          locationLabel: location.districtName,
          days: result.days,
          enabled: true,
        );
      } on PlatformException {
        // Bildirim senkronizasyon hatası yutulur; ana ekranı bozmasın.
      }
    } on PrayerTimesException {
      if (isClosed) {
        return;
      }
      emit(
        const PrayerTimesFailure(
          'Vakitler alınamadı. İnternet bağlantınızı kontrol edip '
          'tekrar deneyin.',
        ),
      );
    }
  }

  Future<bool> requestNotificationPermission() {
    return _notificationBridge.requestNotificationPermission();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) {
      if (isClosed) {
        _timer?.cancel();
        return;
      }
      final current = state;
      if (current is PrayerTimesLoaded) {
        final newStatus = PrayerSchedule(
          current.result.days,
        ).statusAt(_clock.now());
        emit(current.copyWith(status: newStatus));
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
