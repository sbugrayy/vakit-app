// Test edilebilir zaman akışı sağlamak ve doğrudan DateTime.now() kullanımını
// sınırlandırmak amacıyla zaman erişimi bu soyutlama arkasına alınır.

abstract class Clock {
  const Clock();

  DateTime now();
}

class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
