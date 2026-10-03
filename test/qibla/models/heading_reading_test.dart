// HeadingReading ve HeadingAccuracy birim testleri.

import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/qibla/models/heading_reading.dart';

void main() {
  group('HeadingReading', () {
    test('alanları doğru saklar ve props listesini üretir', () {
      const reading = HeadingReading(
        heading: 151.62,
        accuracy: HeadingAccuracy.high,
        trueNorth: true,
      );

      expect(reading.heading, equals(151.62));
      expect(reading.accuracy, equals(HeadingAccuracy.high));
      expect(reading.trueNorth, isTrue);
      expect(
        reading.props,
        equals([151.62, HeadingAccuracy.high, true]),
      );
    });

    test(
      'needsCalibration unreliable ve low için true, diğerlerinde false',
      () {
        const unreliable = HeadingReading(
          heading: 100,
          accuracy: HeadingAccuracy.unreliable,
          trueNorth: false,
        );
        const low = HeadingReading(
          heading: 100,
          accuracy: HeadingAccuracy.low,
          trueNorth: false,
        );
        const medium = HeadingReading(
          heading: 100,
          accuracy: HeadingAccuracy.medium,
          trueNorth: false,
        );
        const high = HeadingReading(
          heading: 100,
          accuracy: HeadingAccuracy.high,
          trueNorth: true,
        );

        expect(unreliable.needsCalibration, isTrue);
        expect(low.needsCalibration, isTrue);
        expect(medium.needsCalibration, isFalse);
        expect(high.needsCalibration, isFalse);
      },
    );

    test('eşitlik ve hashCode beklenen şekilde çalışır', () {
      const reading1 = HeadingReading(
        heading: 151.62,
        accuracy: HeadingAccuracy.high,
        trueNorth: true,
      );
      const reading2 = HeadingReading(
        heading: 151.62,
        accuracy: HeadingAccuracy.high,
        trueNorth: true,
      );
      const differentHeading = HeadingReading(
        heading: 160.17,
        accuracy: HeadingAccuracy.high,
        trueNorth: true,
      );
      const differentAccuracy = HeadingReading(
        heading: 151.62,
        accuracy: HeadingAccuracy.medium,
        trueNorth: true,
      );
      const differentNorth = HeadingReading(
        heading: 151.62,
        accuracy: HeadingAccuracy.high,
        trueNorth: false,
      );

      expect(reading1, equals(reading2));
      expect(reading1.hashCode, equals(reading2.hashCode));
      expect(reading1, isNot(equals(differentHeading)));
      expect(reading1, isNot(equals(differentAccuracy)));
      expect(reading1, isNot(equals(differentNorth)));
    });

    test('HeadingAccuracy tüm enum değerlerini içerir', () {
      expect(
        HeadingAccuracy.values,
        equals([
          HeadingAccuracy.unreliable,
          HeadingAccuracy.low,
          HeadingAccuracy.medium,
          HeadingAccuracy.high,
        ]),
      );
    });
  });
}
