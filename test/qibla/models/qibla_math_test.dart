// qibla_math saf hesap fonksiyonları birim testleri.

import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/qibla/models/qibla_math.dart';

void main() {
  group('qiblaBearing ve distanceToKaabaKm referans şehirler', () {
    test('İstanbul için kıble açısı ve mesafe beklenen aralıkta', () {
      final bearing = qiblaBearing(41.0082, 28.9784);
      final distance = distanceToKaabaKm(41.0082, 28.9784);

      expect(bearing, closeTo(151.62, 0.1));
      expect(distance, closeTo(2405.1, 1));
    });

    test('Ankara için kıble açısı ve mesafe beklenen aralıkta', () {
      final bearing = qiblaBearing(39.9334, 32.8597);
      final distance = distanceToKaabaKm(39.9334, 32.8597);

      expect(bearing, closeTo(160.17, 0.1));
      expect(distance, closeTo(2161.6, 1));
    });

    test('Van için kıble açısı ve mesafe beklenen aralıkta', () {
      final bearing = qiblaBearing(38.5012, 43.3730);
      final distance = distanceToKaabaKm(38.5012, 43.3730);

      expect(bearing, closeTo(191.14, 0.1));
      expect(distance, closeTo(1929.1, 1));
    });

    test('Londra için kıble açısı ve mesafe beklenen aralıkta', () {
      final bearing = qiblaBearing(51.5074, -0.1278);
      final distance = distanceToKaabaKm(51.5074, -0.1278);

      expect(bearing, closeTo(118.99, 0.1));
      expect(distance, closeTo(4793.8, 1));
    });

    test('Cakarta için kıble açısı ve mesafe beklenen aralıkta', () {
      final bearing = qiblaBearing(-6.2088, 106.8456);
      final distance = distanceToKaabaKm(-6.2088, 106.8456);

      expect(bearing, closeTo(295.15, 0.1));
      expect(distance, closeTo(7920.1, 1));
    });

    test('Kâbe koordinatlarında mesafe sıfır döner', () {
      final bearing = qiblaBearing(kaabaLatitude, kaabaLongitude);
      final distance = distanceToKaabaKm(kaabaLatitude, kaabaLongitude);

      expect(bearing, equals(0));
      expect(distance, closeTo(0, 0.001));
    });
  });

  group('turnAngle', () {
    test('örnek senaryolar pozitif dönüş açısı üretir', () {
      expect(
        turnAngle(qibla: 151.6, heading: 350),
        closeTo(161.6, 0.001),
      );
      expect(
        turnAngle(qibla: 10, heading: 350),
        closeTo(20, 0.001),
      );
    });

    test('tam karşı yön 180 derece döner', () {
      expect(turnAngle(qibla: 180, heading: 0), equals(180));
      expect(turnAngle(qibla: 0, heading: 180), equals(180));
      expect(turnAngle(qibla: 270, heading: 90), equals(180));
      expect(turnAngle(qibla: 90, heading: 270), equals(180));
    });

    test('eşitlik durumunda 0 döner', () {
      expect(turnAngle(qibla: 0, heading: 0), equals(0));
      expect(turnAngle(qibla: 120, heading: 120), equals(0));
      expect(turnAngle(qibla: 350, heading: 350), equals(0));
    });

    test('sola dönüş durumunda negatif açı döner', () {
      expect(
        turnAngle(qibla: 350, heading: 10),
        closeTo(-20, 0.001),
      );
      expect(
        turnAngle(qibla: 10, heading: 30),
        closeTo(-20, 0.001),
      );
    });
  });

  group('isAligned', () {
    test('sınırda ve tolerans içinde beklenen değerleri üretir', () {
      expect(isAligned(0), isTrue);
      expect(isAligned(3), isTrue);
      expect(isAligned(-3), isTrue);
      expect(isAligned(2.99), isTrue);
      expect(isAligned(3.01), isFalse);
      expect(isAligned(-3.01), isFalse);
    });

    test('özel tolerans değeriyle doğru çalışır', () {
      expect(isAligned(5, tolerance: 5), isTrue);
      expect(isAligned(-5, tolerance: 5), isTrue);
      expect(isAligned(5.01, tolerance: 5), isFalse);
    });
  });
}
