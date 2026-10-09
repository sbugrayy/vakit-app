// Aylık namaz vakitleri cubit durum modelleri.

import 'package:equatable/equatable.dart';
import 'package:vakit/location/models/selected_location.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';

sealed class MonthlyTimesState extends Equatable {
  const MonthlyTimesState();

  @override
  List<Object?> get props => [];
}

final class MonthlyTimesLoading extends MonthlyTimesState {
  const MonthlyTimesLoading();
}

final class MonthlyTimesNeedsLocation extends MonthlyTimesState {
  const MonthlyTimesNeedsLocation();
}

final class MonthlyTimesLoaded extends MonthlyTimesState {
  const MonthlyTimesLoaded({
    required this.location,
    required this.days,
    required this.todayIndex,
    required this.source,
  });

  final SelectedLocation location;
  final List<PrayerDay> days;
  final int todayIndex;
  final PrayerDataSource source;

  @override
  List<Object?> get props => [location, days, todayIndex, source];
}

final class MonthlyTimesError extends MonthlyTimesState {
  const MonthlyTimesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
