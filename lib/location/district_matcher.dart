// İl ve ilçe adı eşleştirme yardımcıları.

import 'package:vakit/location/models/city.dart';
import 'package:vakit/location/models/district.dart';
import 'package:vakit/location/turkish_text.dart';

String _stripProvinceSuffixes(String folded) {
  if (folded.endsWith(' ILI')) {
    return folded.substring(0, folded.length - 4).trimRight();
  }
  if (folded.endsWith(' PROVINCE')) {
    return folded.substring(0, folded.length - 9).trimRight();
  }
  return folded;
}

String _stripDistrictSuffixes(String folded) {
  if (folded.endsWith(' ILCESI')) {
    return folded.substring(0, folded.length - 7).trimRight();
  }
  if (folded.endsWith(' DISTRICT')) {
    return folded.substring(0, folded.length - 9).trimRight();
  }
  if (folded.endsWith(' MERKEZ')) {
    return folded.substring(0, folded.length - 7).trimRight();
  }
  return folded;
}

City? matchCity(List<City> cities, String provinceName) {
  final target = _stripProvinceSuffixes(foldTurkish(provinceName));
  for (final city in cities) {
    if (foldTurkish(city.name) == target) {
      return city;
    }
  }
  return null;
}

District? matchDistrict(
  List<District> districts, {
  required String cityName,
  String? districtName,
}) {
  if (districtName != null && districtName.trim().isNotEmpty) {
    final targetDistrict = _stripDistrictSuffixes(
      foldTurkish(districtName),
    );
    for (final district in districts) {
      if (foldTurkish(district.name) == targetDistrict) {
        return district;
      }
    }
  }

  final targetCity = _stripProvinceSuffixes(foldTurkish(cityName));
  for (final district in districts) {
    if (foldTurkish(district.name) == targetCity) {
      return district;
    }
  }

  return null;
}
