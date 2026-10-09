// Ters coğrafi kodlama sonucu elde edilen il ve ilçe adları veri modeli.

import 'package:equatable/equatable.dart';

class GeocodedPlace extends Equatable {
  const GeocodedPlace({
    this.province,
    this.district,
  });

  final String? province;
  final String? district;

  @override
  List<Object?> get props => [province, district];
}
