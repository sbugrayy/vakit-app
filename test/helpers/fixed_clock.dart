// Test senaryolarında deterministik zaman kontrolü sağlamak ve zamanı kontrollü
// olarak ilerletmek amacıyla kullanılan Clock uygulaması.

import 'package:vakit/shared/clock.dart';

class FixedClock extends Clock {
  FixedClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}
