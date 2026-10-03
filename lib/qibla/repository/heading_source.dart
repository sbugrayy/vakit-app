// Native yön akışını (EventChannel) dinleyen ve HeadingReading nesnelerine
// dönüştüren kaynak köprüsü.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:vakit/qibla/models/heading_reading.dart';

/// Pusula sensörünün bulunamaması veya okuma yapılamaması durumunda fırlatılır.
class HeadingUnavailableException implements Exception {
  /// İsteğe bağlı hata mesajıyla istisna oluşturur.
  const HeadingUnavailableException([this.message]);

  /// Hatanın açıklaması.
  final String? message;

  @override
  String toString() => message == null
      ? 'HeadingUnavailableException'
      : 'HeadingUnavailableException: $message';
}

/// Native com.sbugrayy.vakit/kible EventChannel akışını yöneten sınıf.
class HeadingSource {
  /// [channel] verilmezse varsayılan [channelName] kanalı kullanılır.
  HeadingSource({EventChannel? channel})
    : _channel = channel ?? const EventChannel(channelName);

  /// Native taraf ile iletişim kurulan EventChannel adı.
  static const channelName = 'com.sbugrayy.vakit/kible';

  final EventChannel _channel;

  /// Native pusula akışını dinler.
  ///
  /// Konum verilirse manyetik sapma hesabı yapılarak gerçek kuzey (trueNorth)
  /// üretilebilir. Sensör yoksa veya olay verisi bozuksa akışa
  /// [HeadingUnavailableException] iletilir.
  Stream<HeadingReading> watch({
    double? latitude,
    double? longitude,
  }) {
    final args = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };

    return _channel
        .receiveBroadcastStream(args)
        .transform(
          StreamTransformer<dynamic, HeadingReading>.fromHandlers(
            handleData: (data, sink) {
              try {
                sink.add(_parseReading(data));
              } on HeadingUnavailableException catch (e) {
                sink.addError(e);
              }
            },
            handleError: (error, stackTrace, sink) {
              if (error is PlatformException && error.code == 'no_sensor') {
                sink.addError(
                  HeadingUnavailableException(error.message ?? 'no_sensor'),
                );
              } else {
                sink.addError(error, stackTrace);
              }
            },
          ),
        );
  }

  static HeadingReading _parseReading(dynamic data) {
    if (data is! Map) {
      throw const HeadingUnavailableException('Olay harita tipinde değil.');
    }

    final rawHeading = data['heading'];
    if (rawHeading is! num || rawHeading.isNaN || rawHeading.isInfinite) {
      throw const HeadingUnavailableException(
        'heading değeri eksik veya geçersiz.',
      );
    }

    final rawAccuracy = data['accuracy'];
    if (rawAccuracy is! int) {
      throw const HeadingUnavailableException(
        'accuracy değeri eksik veya geçersiz.',
      );
    }

    final rawTrueNorth = data['trueNorth'];
    if (rawTrueNorth is! bool) {
      throw const HeadingUnavailableException(
        'trueNorth değeri eksik veya geçersiz.',
      );
    }

    final HeadingAccuracy accuracy;
    switch (rawAccuracy) {
      case 0:
        accuracy = HeadingAccuracy.unreliable;
      case 1:
        accuracy = HeadingAccuracy.low;
      case 2:
        accuracy = HeadingAccuracy.medium;
      case 3:
        accuracy = HeadingAccuracy.high;
      default:
        accuracy = HeadingAccuracy.unreliable;
    }

    return HeadingReading(
      heading: rawHeading.toDouble(),
      accuracy: accuracy,
      trueNorth: rawTrueNorth,
    );
  }
}
