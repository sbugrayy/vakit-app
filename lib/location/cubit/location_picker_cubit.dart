// Konum seçimi durum yönetimi, il ve ilçe getirme, süzme ve kaydetme.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vakit/location/cubit/location_picker_state.dart';
import 'package:vakit/location/models/city.dart';
import 'package:vakit/location/models/district.dart';
import 'package:vakit/location/models/selected_location.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/location/turkish_text.dart';
import 'package:vakit/shared/diyanet/diyanet_api.dart';

class LocationPickerCubit extends Cubit<LocationPickerState> {
  LocationPickerCubit({
    required this._api,
    required this._locationStore,
  }) : super(const LocationPickerState());

  final DiyanetApi _api;
  final LocationStore _locationStore;

  List<City> get visibleCities => state.visibleCities;

  List<District> get visibleDistricts => state.visibleDistricts;

  bool isCenterDistrict(District district) => state.isCenterDistrict(district);

  Future<void> loadCities() async {
    emit(state.copyWith(loading: true, clearErrorMessage: true));

    try {
      final cities = await _api.fetchCities();
      if (isClosed) {
        return;
      }
      final sortedCities = List<City>.of(cities)..sort(_compareCities);
      emit(
        state.copyWith(
          cities: sortedCities,
          loading: false,
          clearErrorMessage: true,
        ),
      );
    } on Exception {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'İller alınamadı. İnternet bağlantınızı kontrol edin.',
        ),
      );
    }
  }

  Future<void> selectCity(City city) async {
    emit(
      state.copyWith(
        step: LocationPickerStep.districts,
        selectedCity: city,
        districts: const [],
        query: '',
        loading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final districts = await _api.fetchDistricts(city.id);
      if (isClosed) {
        return;
      }
      final sortedDistricts = List<District>.of(districts)
        ..sort((a, b) => _compareDistricts(a, b, city));
      emit(
        state.copyWith(
          districts: sortedDistricts,
          loading: false,
          clearErrorMessage: true,
        ),
      );
    } on Exception {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          loading: false,
          errorMessage:
              'İlçeler alınamadı. İnternet bağlantınızı kontrol edin.',
        ),
      );
    }
  }

  void search(String query) {
    emit(state.copyWith(query: query));
  }

  void backToCities() {
    emit(
      state.copyWith(
        step: LocationPickerStep.cities,
        districts: const [],
        clearSelectedCity: true,
        query: '',
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> selectDistrict(District district) async {
    final city = state.selectedCity;
    if (city == null) {
      return;
    }

    final isCenter = isCenterDistrict(district);
    final cityName = displayName(city.name);
    final districtName = isCenter ? cityName : displayName(district.name);

    final selectedLocation = SelectedLocation(
      cityId: city.id,
      cityName: cityName,
      districtId: district.id,
      districtName: districtName,
    );

    try {
      await _locationStore.save(selectedLocation);
      if (isClosed) {
        return;
      }
      emit(state.copyWith(saved: true));
    } on Exception {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          errorMessage:
              'Konum kaydedilemedi. İnternet bağlantınızı kontrol edin.',
        ),
      );
    }
  }

  static int _compareCities(City a, City b) {
    final aKey = foldTurkish(displayName(a.name));
    final bKey = foldTurkish(displayName(b.name));
    final cmp = aKey.compareTo(bKey);
    if (cmp != 0) {
      return cmp;
    }
    return displayName(a.name).compareTo(displayName(b.name));
  }

  static int _compareDistricts(District a, District b, City city) {
    final aCenter = _isCenterDistrict(a, city);
    final bCenter = _isCenterDistrict(b, city);
    if (aCenter && !bCenter) {
      return -1;
    }
    if (!aCenter && bCenter) {
      return 1;
    }
    final aKey = foldTurkish(displayName(a.name));
    final bKey = foldTurkish(displayName(b.name));
    final cmp = aKey.compareTo(bKey);
    if (cmp != 0) {
      return cmp;
    }
    return displayName(a.name).compareTo(displayName(b.name));
  }

  static bool _isCenterDistrict(District district, City city) {
    final districtFolded = foldTurkish(district.name);
    final cityFolded = foldTurkish(city.name);
    return districtFolded == cityFolded || districtFolded == 'MERKEZ';
  }
}
