// Geliştirme ortamında (ör. yerel Norton veya antivirüs TLS taraması) trafiği
// kendi kök sertifikasıyla yeniden imzalayan proxy/güvenlik yazılımları için
// Dio'nun SecurityContext'ine ek kök sertifika yükler.
//
// Yalnızca debug modunda (`isDebug: true`) ve derleme anında açıkça
// `DEV_EXTRA_CA_PEM_B64` tanımlandığında devreye girer. Release derlemelerinde
// ve değer verilmediğinde hiçbir işlem yapmaz (`false` döner).
// Sertifika doğrulaması hiçbir yerde kapatılmaz (`badCertificateCallback`
// kullanılmaz); yalnızca verilen sertifika güvenilen kök sertifikalar arasına
// eklenir.

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

bool applyDevTrustedCertificate(
  Dio dio, {
  String base64Pem = const String.fromEnvironment('DEV_EXTRA_CA_PEM_B64'),
  bool isDebug = kDebugMode,
}) {
  if (!isDebug || base64Pem.isEmpty) {
    return false;
  }

  try {
    final pemBytes = base64.decode(base64Pem);
    final context = SecurityContext(withTrustedRoots: true)
      ..setTrustedCertificatesBytes(pemBytes);
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient(context: context),
    );
    return true;
  } on FormatException catch (e) {
    throw StateError('DEV_EXTRA_CA_PEM_B64 geçersiz: ${e.message}');
  } on TlsException catch (e) {
    throw StateError('DEV_EXTRA_CA_PEM_B64 geçersiz: ${e.message}');
  }
}
