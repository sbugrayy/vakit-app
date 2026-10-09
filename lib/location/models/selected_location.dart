// Kullanıcının seçtiği il/ilçe kimliği, görünen adları ve isteğe bağlı
// coğrafi koordinatlarını temsil eden değişmez veri modeli.

import 'package:equatable/equatable.dart';

class SelectedLocation extends Equatable {
  const SelectedLocation({
    required this.cityId,
    required this.cityName,
    required this.districtId,
    required this.districtName,
    this.latitude,
    this.longitude,
  });

  factory SelectedLocation.fromJson(Map<String, dynamic> json) {
    final cityId = json['cityId'];
    if (cityId is! String) {
      throw const FormatException('cityId alanı eksik veya geçersiz.');
    }

    final cityName = json['cityName'];
    if (cityName is! String) {
      throw const FormatException('cityName alanı eksik veya geçersiz.');
    }

    final districtId = json['districtId'];
    if (districtId is! String) {
      throw const FormatException('districtId alanı eksik veya geçersiz.');
    }

    final districtName = json['districtName'];
    if (districtName is! String) {
      throw const FormatException('districtName alanı eksik veya geçersiz.');
    }

    final rawLatitude = json['latitude'];
    final double? latitude;
    if (rawLatitude == null) {
      latitude = null;
    } else if (rawLatitude is num) {
      latitude = rawLatitude.toDouble();
    } else {
      throw const FormatException('latitude alanı geçersiz tipte.');
    }

    final rawLongitude = json['longitude'];
    final double? longitude;
    if (rawLongitude == null) {
      longitude = null;
    } else if (rawLongitude is num) {
      longitude = rawLongitude.toDouble();
    } else {
      throw const FormatException('longitude alanı geçersiz tipte.');
    }

    return SelectedLocation(
      cityId: cityId,
      cityName: cityName,
      districtId: districtId,
      districtName: districtName,
      latitude: latitude,
      longitude: longitude,
    );
  }

  final String cityId;
  final String cityName;
  final String districtId;
  final String districtName;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'cityId': cityId,
    'cityName': cityName,
    'districtId': districtId,
    'districtName': districtName,
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  List<Object?> get props => [
    cityId,
    cityName,
    districtId,
    districtName,
    latitude,
    longitude,
  ];
}
