// Diyanet namaz vakitleri, şehir ve ilçe API uçlarına erişim sağlayan istemci.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:vakit/location/models/city.dart';
import 'package:vakit/location/models/district.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';
import 'package:vakit/shared/diyanet/dev_certificate.dart';
import 'package:vakit/shared/diyanet/diyanet_api_exception.dart';

class DiyanetApi {
  DiyanetApi({Dio? dio}) : _dio = dio ?? _createDefaultDio();

  static const turkeyCountryId = '2';

  final Dio _dio;

  Future<List<City>> fetchCities({
    String countryId = turkeyCountryId,
  }) async {
    final body = await _get('/sehirler/$countryId');
    return _parseList(body, 'Şehir', City.fromDiyanetJson);
  }

  Future<List<District>> fetchDistricts(String cityId) async {
    final body = await _get('/ilceler/$cityId');
    return _parseList(body, 'İlçe', District.fromDiyanetJson);
  }

  Future<String> fetchPrayerDaysJson(String districtId) async {
    final body = await _get('/vakitler/$districtId');
    _parseAndValidatePrayerDays(body);
    return body;
  }

  Future<List<PrayerDay>> fetchPrayerDays(String districtId) async {
    final body = await fetchPrayerDaysJson(districtId);
    return _parseAndValidatePrayerDays(body);
  }

  Future<String> _get(String path) async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(path);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    if (response.statusCode != 200) {
      throw DiyanetApiException(
        kind: DiyanetApiErrorKind.badResponse,
        message: 'Beklenmeyen HTTP durum kodu: ${response.statusCode}',
      );
    }

    final data = response.data;
    if (data is! String) {
      throw const DiyanetApiException(
        kind: DiyanetApiErrorKind.invalidData,
        message: 'Yanıt gövdesi metin (String) değil',
      );
    }

    return data;
  }

  List<T> _parseList<T>(
    String body,
    String listName,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final decoded = _decodeJsonList(body, listName);
    try {
      final list = <T>[];
      for (var i = 0; i < decoded.length; i++) {
        final item = decoded[i];
        if (item is! Map<String, dynamic>) {
          throw FormatException(
            '$listName listesi öğesi Map olmalı (indeks: $i)',
          );
        }
        list.add(fromJson(item));
      }
      return List.unmodifiable(list);
    } on FormatException catch (e) {
      throw DiyanetApiException(
        kind: DiyanetApiErrorKind.invalidData,
        message: e.message,
      );
    }
  }

  List<PrayerDay> _parseAndValidatePrayerDays(String body) {
    final decoded = _decodeJsonList(body, 'Vakit listesi');
    final List<PrayerDay> days;
    try {
      days = PrayerDay.listFromDiyanetJson(decoded);
    } on FormatException catch (e) {
      throw DiyanetApiException(
        kind: DiyanetApiErrorKind.invalidData,
        message: 'Vakit listesi çözümlenemedi: ${e.message}',
      );
    }

    if (days.isEmpty) {
      throw const DiyanetApiException(
        kind: DiyanetApiErrorKind.invalidData,
        message: 'Diyanet vakit listesi boş dönemez',
      );
    }

    return days;
  }

  List<dynamic> _decodeJsonList(String body, String contextLabel) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (e) {
      throw DiyanetApiException(
        kind: DiyanetApiErrorKind.invalidData,
        message: 'Geçersiz JSON ($contextLabel): ${e.message}',
      );
    }

    if (decoded is! List<dynamic>) {
      throw DiyanetApiException(
        kind: DiyanetApiErrorKind.invalidData,
        message:
            'Beklenmeyen JSON yapısı: Dizi beklenirken '
            '${decoded.runtimeType} geldi ($contextLabel)',
      );
    }

    return decoded;
  }

  DiyanetApiException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return DiyanetApiException(
          kind: DiyanetApiErrorKind.timeout,
          message: e.message ?? 'İstek zaman aşımına uğradı',
        );
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final statusText = status != null ? 'HTTP $status' : 'durum bilinmiyor';
        return DiyanetApiException(
          kind: DiyanetApiErrorKind.badResponse,
          message: 'Sunucu hatası: $statusText',
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return DiyanetApiException(
          kind: DiyanetApiErrorKind.network,
          message: e.message ?? 'Ağ hatası',
        );
    }
  }

  static Dio _createDefaultDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://ezanvakti.emushaf.net',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        responseType: ResponseType.plain,
      ),
    );
    applyDevTrustedCertificate(dio);
    return dio;
  }
}
