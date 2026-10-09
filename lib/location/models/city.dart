// Diyanet API'sinden alınan şehir bilgisini temsil eden model.

import 'package:equatable/equatable.dart';

class City extends Equatable {
  const City({
    required this.id,
    required this.name,
  });

  factory City.fromDiyanetJson(Map<String, dynamic> json) {
    final rawId = json['SehirID'];
    if (rawId is! String) {
      throw const FormatException('Eksik veya geçersiz SehirID');
    }
    final rawName = json['SehirAdi'];
    if (rawName is! String) {
      throw const FormatException('Eksik veya geçersiz SehirAdi');
    }
    return City(
      id: rawId,
      name: rawName,
    );
  }

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
