// Native bildirim motoruyla iletişim kuran MethodChannel köprüsü.

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:vakit/prayer_times/models/prayer.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';

class NotificationStatus extends Equatable {
  const NotificationStatus({
    required this.notificationsGranted,
    required this.exactAlarmAllowed,
    required this.enabled,
  });

  factory NotificationStatus.fromMap(Map<dynamic, dynamic> map) {
    return NotificationStatus(
      notificationsGranted: map['notificationsGranted'] == true,
      exactAlarmAllowed: map['exactAlarmAllowed'] == true,
      enabled: map['enabled'] == true,
    );
  }

  static const unavailable = NotificationStatus(
    notificationsGranted: false,
    exactAlarmAllowed: false,
    enabled: false,
  );

  final bool notificationsGranted;
  final bool exactAlarmAllowed;
  final bool enabled;

  @override
  List<Object?> get props => [
    notificationsGranted,
    exactAlarmAllowed,
    enabled,
  ];
}

class NotificationBridge {
  NotificationBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.sbugrayy.vakit/bildirim';

  final MethodChannel _channel;

  static String buildPayload({
    required String locationLabel,
    required List<PrayerDay> days,
  }) {
    final payload = <String, dynamic>{
      'locationLabel': locationLabel,
      'utcOffsetMinutes': days.isEmpty ? 0 : days.first.utcOffset.inMinutes,
      'days': days
          .map(
            (day) => <String, dynamic>{
              'date': _formatUtcDate(day.date),
              'times': Prayer.values
                  .map(
                    (prayer) => <String, dynamic>{
                      'key': prayer.name,
                      'label': prayer.label,
                      'epochMillis': day.timeOf(prayer).millisecondsSinceEpoch,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    };
    return jsonEncode(payload);
  }

  static String _formatUtcDate(DateTime date) {
    final utc = date.toUtc();
    final year = utc.year.toString().padLeft(4, '0');
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> sync({
    required String locationLabel,
    required List<PrayerDay> days,
    required bool enabled,
  }) async {
    final payload = buildPayload(
      locationLabel: locationLabel,
      days: days,
    );
    try {
      await _channel.invokeMethod<void>(
        'syncSchedule',
        <String, dynamic>{
          'payload': payload,
          'enabled': enabled,
        },
      );
    } on MissingPluginException {
      // Android dışı veya test ortamında sessizce devam edilir.
    }
  }

  Future<void> setEnabled({required bool enabled}) async {
    try {
      await _channel.invokeMethod<void>(
        'setEnabled',
        <String, dynamic>{
          'enabled': enabled,
        },
      );
    } on MissingPluginException {
      // Android dışı veya test ortamında sessizce devam edilir.
    }
  }

  Future<NotificationStatus> status() async {
    try {
      final result = await _channel.invokeMethod<dynamic>('getStatus');
      if (result is Map) {
        return NotificationStatus.fromMap(result);
      }
      return NotificationStatus.unavailable;
    } on MissingPluginException {
      return NotificationStatus.unavailable;
    }
  }

  Future<bool> requestNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'requestNotificationPermission',
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> openExactAlarmSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'openExactAlarmSettings',
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
