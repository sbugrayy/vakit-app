// Prayer enum sırası ve Türkçe etiketlerinin doğrulanması.

import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/prayer_times/models/prayer.dart';

void main() {
  group('Prayer', () {
    test('kronolojik sırayla 6 vakit içerir', () {
      expect(
        Prayer.values,
        equals([
          Prayer.imsak,
          Prayer.gunes,
          Prayer.ogle,
          Prayer.ikindi,
          Prayer.aksam,
          Prayer.yatsi,
        ]),
      );
    });

    test('bütün vakitler doğru Türkçe etiketlere sahiptir', () {
      expect(Prayer.imsak.label, equals('İmsak'));
      expect(Prayer.gunes.label, equals('Güneş'));
      expect(Prayer.ogle.label, equals('Öğle'));
      expect(Prayer.ikindi.label, equals('İkindi'));
      expect(Prayer.aksam.label, equals('Akşam'));
      expect(Prayer.yatsi.label, equals('Yatsı'));
    });
  });
}
