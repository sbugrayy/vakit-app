// Kıble hesaplama ve pusula akışı yönetim Cubit'i.

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/qibla/cubit/qibla_state.dart';
import 'package:vakit/qibla/models/heading_reading.dart';
import 'package:vakit/qibla/models/qibla_math.dart';
import 'package:vakit/qibla/repository/heading_source.dart';

class QiblaCubit extends Cubit<QiblaState> {
  QiblaCubit({
    required this._locationStore,
    required this._headingSource,
  }) : super(const QiblaInitial());

  final LocationStore _locationStore;
  final HeadingSource _headingSource;

  StreamSubscription<HeadingReading>? _headingSubscription;

  Future<void> start() async {
    await _headingSubscription?.cancel();
    _headingSubscription = null;

    final location = await _locationStore.load();
    if (isClosed) {
      return;
    }

    if (location == null || !location.hasCoordinates) {
      emit(const QiblaNeedsCoordinates());
      return;
    }

    final lat = location.latitude!;
    final lon = location.longitude!;
    final bearing = qiblaBearing(lat, lon);
    final distanceKm = distanceToKaabaKm(lat, lon);

    emit(QiblaReady(bearing: bearing, distanceKm: distanceKm));

    _headingSubscription = _headingSource
        .watch(latitude: lat, longitude: lon)
        .listen(
          (reading) {
            if (isClosed) {
              return;
            }
            final turn = turnAngle(qibla: bearing, heading: reading.heading);
            final aligned = isAligned(turn);
            emit(
              QiblaReady(
                bearing: bearing,
                distanceKm: distanceKm,
                reading: reading,
                turn: turn,
                aligned: aligned,
              ),
            );
          },
          onError: (Object error) {
            if (isClosed) {
              return;
            }
            if (error is HeadingUnavailableException) {
              emit(
                const QiblaUnavailable(
                  'Bu cihazda pusula sensörü bulunamadı.',
                ),
              );
            } else {
              emit(
                const QiblaUnavailable(
                  'Bu cihazda pusula sensörü bulunamadı.',
                ),
              );
            }
          },
        );
  }

  @override
  Future<void> close() async {
    await _headingSubscription?.cancel();
    return super.close();
  }
}
