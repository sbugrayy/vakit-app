// Native konum kanalı üzerinden cihaz konumunu ve ters coğrafi kodlamayı
// yöneten köprü servis.

import 'package:flutter/services.dart';
import 'package:vakit/location/models/geo_point.dart';
import 'package:vakit/location/models/geocoded_place.dart';

enum DeviceLocationError {
  permissionDenied,
  unavailable,
}

class DeviceLocationException implements Exception {
  const DeviceLocationException(this.error, [this.message]);

  final DeviceLocationError error;
  final String? message;

  @override
  String toString() => 'DeviceLocationException($error, $message)';
}

class DeviceLocation {
  DeviceLocation({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.sbugrayy.vakit/konum';

  final MethodChannel _channel;

  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'requestLocationPermission',
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<GeoPoint> currentLocation() async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'getCurrentLocation',
      );
      if (result == null) {
        throw const DeviceLocationException(DeviceLocationError.unavailable);
      }
      final lat = result['latitude'];
      final lon = result['longitude'];
      if (lat is! num || lon is! num) {
        throw const DeviceLocationException(DeviceLocationError.unavailable);
      }
      return GeoPoint(
        latitude: lat.toDouble(),
        longitude: lon.toDouble(),
      );
    } on DeviceLocationException {
      rethrow;
    } on PlatformException catch (e) {
      if (e.code == 'permission_denied') {
        throw DeviceLocationException(
          DeviceLocationError.permissionDenied,
          e.message,
        );
      }
      throw DeviceLocationException(
        DeviceLocationError.unavailable,
        e.message,
      );
    } on MissingPluginException catch (e) {
      throw DeviceLocationException(
        DeviceLocationError.unavailable,
        e.message,
      );
    }
  }

  Future<GeocodedPlace> reverseGeocode(GeoPoint point) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'reverseGeocode',
        <String, dynamic>{
          'latitude': point.latitude,
          'longitude': point.longitude,
        },
      );
      if (result == null) {
        throw const DeviceLocationException(DeviceLocationError.unavailable);
      }
      final rawProvince = result['province'];
      final rawDistrict = result['district'];
      if ((rawProvince != null && rawProvince is! String) ||
          (rawDistrict != null && rawDistrict is! String)) {
        throw const DeviceLocationException(DeviceLocationError.unavailable);
      }
      return GeocodedPlace(
        province: rawProvince as String?,
        district: rawDistrict as String?,
      );
    } on DeviceLocationException {
      rethrow;
    } on PlatformException catch (e) {
      throw DeviceLocationException(
        DeviceLocationError.unavailable,
        e.message,
      );
    } on MissingPluginException catch (e) {
      throw DeviceLocationException(
        DeviceLocationError.unavailable,
        e.message,
      );
    }
  }
}
