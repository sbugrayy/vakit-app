// Diyanet API'sinden alınan ilçe bilgisini temsil eden model.

import 'package:equatable/equatable.dart';

class District extends Equatable {
  const District({
    required this.id,
    required this.name,
  });

  factory District.fromDiyanetJson(Map<String, dynamic> json) {
    final rawId = json['IlceID'];
    if (rawId is! String) {
      throw const FormatException('Eksik veya geçersiz IlceID');
    }
    final rawName = json['IlceAdi'];
    if (rawName is! String) {
      throw const FormatException('Eksik veya geçersiz IlceAdi');
    }
    return District(
      id: rawId,
      name: rawName,
    );
  }

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
