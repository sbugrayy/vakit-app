// Kıble modülü Cubit durumları.

import 'package:equatable/equatable.dart';
import 'package:vakit/qibla/models/heading_reading.dart';

sealed class QiblaState extends Equatable {
  const QiblaState();

  @override
  List<Object?> get props => [];
}

final class QiblaInitial extends QiblaState {
  const QiblaInitial();
}

final class QiblaNeedsCoordinates extends QiblaState {
  const QiblaNeedsCoordinates();
}

final class QiblaUnavailable extends QiblaState {
  const QiblaUnavailable(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class QiblaReady extends QiblaState {
  const QiblaReady({
    required this.bearing,
    required this.distanceKm,
    this.reading,
    this.turn,
    this.aligned = false,
  });

  final double bearing;
  final double distanceKm;
  final HeadingReading? reading;
  final double? turn;
  final bool aligned;

  QiblaReady copyWith({
    double? bearing,
    double? distanceKm,
    HeadingReading? reading,
    double? turn,
    bool? aligned,
  }) {
    return QiblaReady(
      bearing: bearing ?? this.bearing,
      distanceKm: distanceKm ?? this.distanceKm,
      reading: reading ?? this.reading,
      turn: turn ?? this.turn,
      aligned: aligned ?? this.aligned,
    );
  }

  @override
  List<Object?> get props => [bearing, distanceKm, reading, turn, aligned];
}
