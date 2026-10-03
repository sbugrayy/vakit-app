// Coğrafi enlem ve boylam koordinatlarını temsil eden değişmez veri modeli.

import 'package:equatable/equatable.dart';

class GeoPoint extends Equatable {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}
