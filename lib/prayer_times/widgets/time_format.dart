// Namaz vakti ekranlarında saat, geri sayım ve tarih biçimleme fonksiyonları.

import 'package:intl/intl.dart';

String formatClock(DateTime utc, Duration offset) {
  final local = utc.toUtc().add(offset);
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatCountdown(Duration d) {
  if (d.isNegative) {
    return '00:00:00';
  }
  final hours = d.inHours.toString().padLeft(2, '0');
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

String formatLongDate(DateTime dateUtc) {
  final utc = dateUtc.toUtc();
  final calendarDate = DateTime.utc(utc.year, utc.month, utc.day);
  return DateFormat('d MMMM y EEEE', 'tr').format(calendarDate);
}
