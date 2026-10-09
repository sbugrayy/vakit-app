// Diyanet API çağrılarında oluşan hataları türlerine göre gruplayan istisna.

enum DiyanetApiErrorKind {
  network,
  timeout,
  badResponse,
  invalidData,
}

class DiyanetApiException implements Exception {
  const DiyanetApiException({
    required this.kind,
    required this.message,
  });

  final DiyanetApiErrorKind kind;
  final String message;

  @override
  String toString() => 'DiyanetApiException($kind, $message)';
}
