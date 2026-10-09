// Konum seçimi cubit durum modelleri ve adım tanımları.

import 'package:equatable/equatable.dart';
import 'package:vakit/location/models/city.dart';
import 'package:vakit/location/models/district.dart';
import 'package:vakit/location/models/geo_point.dart';
import 'package:vakit/location/turkish_text.dart';

enum LocationPickerStep { cities, districts }

class LocationPickerState extends Equatable {
  const LocationPickerState({
    this.step = LocationPickerStep.cities,
    this.cities = const [],
    this.districts = const [],
    this.selectedCity,
    this.query = '',
    this.loading = false,
    this.locating = false,
    this.errorMessage,
    this.pendingPoint,
    this.saved = false,
  });

  final LocationPickerStep step;
  final List<City> cities;
  final List<District> districts;
  final City? selectedCity;
  final String query;
  final bool loading;
  final bool locating;
  final String? errorMessage;
  final GeoPoint? pendingPoint;
  final bool saved;

  List<City> get visibleCities {
    final foldedQuery = foldTurkish(query);
    if (foldedQuery.isEmpty) {
      return cities;
    }
    return cities
        .where((city) => foldTurkish(city.name).contains(foldedQuery))
        .toList();
  }

  List<District> get visibleDistricts {
    final foldedQuery = foldTurkish(query);
    if (foldedQuery.isEmpty) {
      return districts;
    }
    return districts
        .where(
          (district) => foldTurkish(district.name).contains(foldedQuery),
        )
        .toList();
  }

  bool isCenterDistrict(District district) {
    final city = selectedCity;
    if (city == null) {
      return false;
    }
    final districtFolded = foldTurkish(district.name);
    final cityFolded = foldTurkish(city.name);
    return districtFolded == cityFolded || districtFolded == 'MERKEZ';
  }

  LocationPickerState copyWith({
    LocationPickerStep? step,
    List<City>? cities,
    List<District>? districts,
    City? selectedCity,
    bool clearSelectedCity = false,
    String? query,
    bool? loading,
    bool? locating,
    String? errorMessage,
    bool clearErrorMessage = false,
    GeoPoint? pendingPoint,
    bool clearPendingPoint = false,
    bool? saved,
  }) {
    return LocationPickerState(
      step: step ?? this.step,
      cities: cities ?? this.cities,
      districts: districts ?? this.districts,
      selectedCity: clearSelectedCity
          ? null
          : (selectedCity ?? this.selectedCity),
      query: query ?? this.query,
      loading: loading ?? this.loading,
      locating: locating ?? this.locating,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      pendingPoint: clearPendingPoint
          ? null
          : (pendingPoint ?? this.pendingPoint),
      saved: saved ?? this.saved,
    );
  }

  @override
  List<Object?> get props => [
    step,
    cities,
    districts,
    selectedCity,
    query,
    loading,
    locating,
    errorMessage,
    pendingPoint,
    saved,
  ];
}
