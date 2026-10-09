// Kıble açısı, Kâbe mesafesi ve pusula hizalama hesaplamaları.

import 'dart:math' as math;

/// Kâbe'nin enlem koordinatı (Mekke).
const double kaabaLatitude = 21.4225241;

/// Kâbe'nin boylam koordinatı (Mekke).
const double kaabaLongitude = 39.8261818;

/// Haversine formülü için Dünya yarıçapı (km).
const double earthRadiusKm = 6371.0088;

double _degreesToRadians(double degrees) => degrees * (math.pi / 180);

double _radiansToDegrees(double radians) => radians * (180 / math.pi);

/// Verilen enlem ve boylamdan Kâbe'ye doğru büyük çember başlangıç açısını
/// gerçek kuzeye göre [0, 360) derece aralığında döndürür.
double qiblaBearing(double latitude, double longitude) {
  final phi1 = _degreesToRadians(latitude);
  final lambda1 = _degreesToRadians(longitude);
  final phi2 = _degreesToRadians(kaabaLatitude);
  final lambda2 = _degreesToRadians(kaabaLongitude);
  final deltaLambda = lambda2 - lambda1;

  final y = math.sin(deltaLambda) * math.cos(phi2);
  final x =
      math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

  final initialBearingRad = math.atan2(y, x);
  final initialBearingDeg = _radiansToDegrees(initialBearingRad);
  final normalized = initialBearingDeg % 360;
  return normalized == 0 ? 0 : normalized;
}

/// Verilen enlem ve boylamdan Kâbe'ye olan mesafeyi Haversine formülüyle
/// kilometre cinsinden hesaplar.
double distanceToKaabaKm(double latitude, double longitude) {
  final phi1 = _degreesToRadians(latitude);
  final lambda1 = _degreesToRadians(longitude);
  final phi2 = _degreesToRadians(kaabaLatitude);
  final lambda2 = _degreesToRadians(kaabaLongitude);

  final deltaPhi = phi2 - phi1;
  final deltaLambda = lambda2 - lambda1;

  final sinHalfDeltaPhi = math.sin(deltaPhi / 2);
  final sinHalfDeltaLambda = math.sin(deltaLambda / 2);

  final a =
      sinHalfDeltaPhi * sinHalfDeltaPhi +
      math.cos(phi1) * math.cos(phi2) * sinHalfDeltaLambda * sinHalfDeltaLambda;

  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(math.max(0, 1 - a)));
  return earthRadiusKm * c;
}

/// Pusula yönü [heading] ile kıble açısı [qibla] arasındaki dönülmesi gereken
/// açıyı (-180, 180] derece aralığında döndürür.
/// Pozitif değer sağa (saat yönü), negatif değer sola dönmeyi ifade eder.
double turnAngle({required double qibla, required double heading}) {
  final diff = (qibla - heading) % 360;
  if (diff > 180) {
    return diff - 360;
  }
  return diff == 0 ? 0 : diff;
}

/// Dönüş açısının [tolerance] derece aralığında olup olmadığını kontrol eder.
/// |turnAngle| <= tolerance ise kullanıcı kıbleye hizalanmış sayılır.
bool isAligned(double turnAngle, {double tolerance = 3}) {
  return turnAngle.abs() <= tolerance;
}
