// Namaz vakitleri cubit durum modelleri.

import 'package:equatable/equatable.dart';
import 'package:vakit/location/models/selected_location.dart';
import 'package:vakit/prayer_times/models/prayer_schedule.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';

sealed class PrayerTimesState extends Equatable {
  const PrayerTimesState();

  @override
  List<Object?> get props => [];
}

final class PrayerTimesInitial extends PrayerTimesState {
  const PrayerTimesInitial();
}

final class PrayerTimesLoading extends PrayerTimesState {
  const PrayerTimesLoading();
}

final class PrayerTimesNeedsLocation extends PrayerTimesState {
  const PrayerTimesNeedsLocation();
}

final class PrayerTimesFailure extends PrayerTimesState {
  const PrayerTimesFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class PrayerTimesLoaded extends PrayerTimesState {
  const PrayerTimesLoaded({
    required this.location,
    required this.result,
    required this.status,
  });

  final SelectedLocation location;
  final PrayerTimesResult result;
  final ScheduleStatus status;

  PrayerTimesLoaded copyWith({
    SelectedLocation? location,
    PrayerTimesResult? result,
    ScheduleStatus? status,
  }) {
    return PrayerTimesLoaded(
      location: location ?? this.location,
      result: result ?? this.result,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [location, result, status];
}
