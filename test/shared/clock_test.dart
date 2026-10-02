// Clock sözleşmesi, SystemClock ve FixedClock davranışlarının doğrulanması.

import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/shared/clock.dart';

import '../helpers/fixed_clock.dart';

void main() {
  group('SystemClock', () {
    test('Clock arayüzünü uygular', () {
      expect(const SystemClock(), isA<Clock>());
    });

    test('now() anlık sistem zamanını sınırlar dahilinde döner', () {
      final before = DateTime.now();
      final now = const SystemClock().now();
      final after = DateTime.now();

      expect(now.isBefore(before), isFalse);
      expect(now.isAfter(after), isFalse);
    });
  });

  group('FixedClock', () {
    test('Clock arayüzünü uygular', () {
      final clock = FixedClock(DateTime.utc(2026, 10, 2, 12));
      expect(clock, isA<Clock>());
    });

    test('verilen başlangıç zamanını döner', () {
      final initialTime = DateTime.utc(2026, 10, 2, 12);
      final clock = FixedClock(initialTime);

      expect(clock.now(), equals(initialTime));
    });

    test('advance ile zaman doğru ilerler', () {
      final initialTime = DateTime.utc(2026, 10, 2, 12);
      final clock = FixedClock(initialTime)
        ..advance(const Duration(minutes: 15));

      expect(
        clock.now(),
        equals(DateTime.utc(2026, 10, 2, 12, 15)),
      );
    });

    test('art arda iki advance toplanır', () {
      final initialTime = DateTime.utc(2026, 10, 2, 12);
      final clock = FixedClock(initialTime)
        ..advance(const Duration(hours: 1))
        ..advance(const Duration(minutes: 30));

      expect(
        clock.now(),
        equals(DateTime.utc(2026, 10, 2, 13, 30)),
      );
    });
  });
}
