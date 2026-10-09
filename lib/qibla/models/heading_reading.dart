// Native sensörden gelen pusula yönü ve doğruluk verisi modeli.

import 'package:equatable/equatable.dart';

/// Pusula sensörünün doğruluk durumu (Android SENSOR_STATUS_* karşılıkları).
enum HeadingAccuracy {
  /// Güvenilmez (SENSOR_STATUS_UNRELIABLE = 0).
  unreliable,

  /// Düşük doğruluk (SENSOR_STATUS_ACCURACY_LOW = 1).
  low,

  /// Orta doğruluk (SENSOR_STATUS_ACCURACY_MEDIUM = 2).
  medium,

  /// Yüksek doğruluk (SENSOR_STATUS_ACCURACY_HIGH = 3).
  high,
}

/// Native sensör akışından okunan anlık pusula yönü ve doğruluk değeri.
class HeadingReading extends Equatable {
  /// [heading], [accuracy] ve [trueNorth] değerleriyle pusula okuması
  /// oluşturur.
  const HeadingReading({
    required this.heading,
    required this.accuracy,
    required this.trueNorth,
  });

  /// Pusula açısı (derece cinsinden, [0, 360) aralığında).
  final double heading;

  /// Sensörün doğruluk durumu.
  final HeadingAccuracy accuracy;

  /// Açının manyetik kuzey yerine gerçek kuzeye göre hesaplanıp hesaplanmadığı.
  final bool trueNorth;

  /// Doğruluk güvenilmez ya da düşükse kalibrasyon gerektiğini belirtir.
  bool get needsCalibration =>
      accuracy == HeadingAccuracy.unreliable || accuracy == HeadingAccuracy.low;

  @override
  List<Object?> get props => [heading, accuracy, trueNorth];
}
