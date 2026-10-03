// LocationPickerCubit birim testleri.

import 'dart:convert';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vakit/location/cubit/location_picker_cubit.dart';
import 'package:vakit/location/cubit/location_picker_state.dart';
import 'package:vakit/location/models/city.dart';
import 'package:vakit/location/models/district.dart';
import 'package:vakit/location/models/selected_location.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/location/turkish_text.dart';
import 'package:vakit/shared/diyanet/diyanet_api.dart';
import 'package:vakit/shared/diyanet/diyanet_api_exception.dart';

class _MockDiyanetApi extends Mock implements DiyanetApi {}

class _MockLocationStore extends Mock implements LocationStore {}

void main() {
  const istanbulCity = City(id: '539', name: 'İSTANBUL');
  const vanCity = City(id: '577', name: 'VAN');

  late _MockDiyanetApi api;
  late _MockLocationStore locationStore;
  late List<City> citiesFixture;
  late List<District> istanbulDistrictsFixture;
  late List<District> vanDistrictsFixture;

  setUpAll(() {
    registerFallbackValue(
      const SelectedLocation(
        cityId: 'fallback',
        cityName: 'fallback',
        districtId: 'fallback',
        districtName: 'fallback',
      ),
    );

    final citiesJson = File(
      'test/fixtures/diyanet/sehirler_2.json',
    ).readAsStringSync();
    citiesFixture = (jsonDecode(citiesJson) as List<dynamic>)
        .map((e) => City.fromDiyanetJson(e as Map<String, dynamic>))
        .toList();

    final istanbulDistrictsJson = File(
      'test/fixtures/diyanet/ilceler_539.json',
    ).readAsStringSync();
    istanbulDistrictsFixture =
        (jsonDecode(istanbulDistrictsJson) as List<dynamic>)
            .map((e) => District.fromDiyanetJson(e as Map<String, dynamic>))
            .toList();

    final vanDistrictsJson = File(
      'test/fixtures/diyanet/ilceler_577.json',
    ).readAsStringSync();
    vanDistrictsFixture = (jsonDecode(vanDistrictsJson) as List<dynamic>)
        .map((e) => District.fromDiyanetJson(e as Map<String, dynamic>))
        .toList();
  });

  setUp(() {
    api = _MockDiyanetApi();
    locationStore = _MockLocationStore();
  });

  group('LocationPickerCubit', () {
    blocTest<LocationPickerCubit, LocationPickerState>(
      'loadCities: 81 il, sıralı (ilk ilin displayName i Adana)',
      build: () {
        when(api.fetchCities).thenAnswer((_) async => citiesFixture);
        return LocationPickerCubit(api: api, locationStore: locationStore);
      },
      act: (cubit) => cubit.loadCities(),
      verify: (cubit) {
        expect(cubit.state.cities.length, 81);
        expect(displayName(cubit.state.cities.first.name), 'Adana');
        expect(cubit.state.loading, isFalse);
        expect(cubit.state.errorMessage, isNull);
      },
    );

    blocTest<LocationPickerCubit, LocationPickerState>(
      'loadCities hata durumunda errorMessage yayınlar',
      build: () {
        when(api.fetchCities).thenThrow(
          const DiyanetApiException(
            kind: DiyanetApiErrorKind.network,
            message: 'Ağ hatası',
          ),
        );
        return LocationPickerCubit(api: api, locationStore: locationStore);
      },
      act: (cubit) => cubit.loadCities(),
      expect: () => [
        const LocationPickerState(loading: true),
        const LocationPickerState(
          errorMessage: 'İller alınamadı. İnternet bağlantınızı kontrol edin.',
        ),
      ],
    );

    blocTest<LocationPickerCubit, LocationPickerState>(
      'selectCity(İstanbul) -> 19 ilçe, ilk sırada İSTANBUL (merkez), '
      'step: districts',
      build: () {
        when(
          () => api.fetchDistricts('539'),
        ).thenAnswer((_) async => istanbulDistrictsFixture);
        return LocationPickerCubit(api: api, locationStore: locationStore);
      },
      act: (cubit) => cubit.selectCity(istanbulCity),
      verify: (cubit) {
        expect(cubit.state.step, LocationPickerStep.districts);
        expect(cubit.state.selectedCity, istanbulCity);
        expect(cubit.state.districts.length, 19);
        expect(cubit.state.districts.first.name, 'İSTANBUL');
        expect(cubit.isCenterDistrict(cubit.state.districts.first), isTrue);
      },
    );

    blocTest<LocationPickerCubit, LocationPickerState>(
      'selectCity hata durumunda errorMessage yayınlar',
      build: () {
        when(
          () => api.fetchDistricts('539'),
        ).thenThrow(
          const DiyanetApiException(
            kind: DiyanetApiErrorKind.network,
            message: 'Ağ hatası',
          ),
        );
        return LocationPickerCubit(api: api, locationStore: locationStore);
      },
      act: (cubit) => cubit.selectCity(istanbulCity),
      expect: () => [
        const LocationPickerState(
          step: LocationPickerStep.districts,
          selectedCity: istanbulCity,
          loading: true,
        ),
        const LocationPickerState(
          step: LocationPickerStep.districts,
          selectedCity: istanbulCity,
          errorMessage:
              'İlçeler alınamadı. İnternet bağlantınızı kontrol edin.',
        ),
      ],
    );

    test(
      'search(başak) -> yalnız BAŞAKŞEHİR; search(KADI) -> boş liste',
      () async {
        when(
          () => api.fetchDistricts('539'),
        ).thenAnswer((_) async => istanbulDistrictsFixture);
        final cubit = LocationPickerCubit(
          api: api,
          locationStore: locationStore,
        );
        await cubit.selectCity(istanbulCity);

        cubit.search('başak');
        expect(cubit.state.query, 'başak');
        expect(
          cubit.visibleDistricts.map((d) => d.name).toList(),
          ['BAŞAKŞEHİR'],
        );

        cubit.search('KADI');
        expect(cubit.visibleDistricts, isEmpty);
        await cubit.close();
      },
    );

    test('Van da search(edremit) -> EDREMİT (V)', () async {
      when(
        () => api.fetchDistricts('577'),
      ).thenAnswer((_) async => vanDistrictsFixture);
      final cubit = LocationPickerCubit(api: api, locationStore: locationStore);
      await cubit.selectCity(vanCity);

      cubit.search('edremit');
      expect(
        cubit.visibleDistricts.map((d) => d.name).toList(),
        ['EDREMİT (V)'],
      );
      await cubit.close();
    });

    test(
      'selectDistrict(BAŞAKŞEHİR) -> LocationStore.save doğru '
      'SelectedLocation ile çağrılır, saved: true',
      () async {
        when(
          () => api.fetchDistricts('539'),
        ).thenAnswer((_) async => istanbulDistrictsFixture);
        when(() => locationStore.save(any())).thenAnswer((_) async {});

        final cubit = LocationPickerCubit(
          api: api,
          locationStore: locationStore,
        );
        await cubit.selectCity(istanbulCity);

        final basaksehir = istanbulDistrictsFixture.firstWhere(
          (d) => d.name == 'BAŞAKŞEHİR',
        );

        await cubit.selectDistrict(basaksehir);

        verify(
          () => locationStore.save(
            const SelectedLocation(
              cityId: '539',
              cityName: 'İstanbul',
              districtId: '17866',
              districtName: 'Başakşehir',
            ),
          ),
        ).called(1);

        expect(cubit.state.saved, isTrue);
        await cubit.close();
      },
    );

    test(
      'selectDistrict(İSTANBUL) merkez ilçe seçilirse districtName '
      'il adıdır',
      () async {
        when(
          () => api.fetchDistricts('539'),
        ).thenAnswer((_) async => istanbulDistrictsFixture);
        when(() => locationStore.save(any())).thenAnswer((_) async {});

        final cubit = LocationPickerCubit(
          api: api,
          locationStore: locationStore,
        );
        await cubit.selectCity(istanbulCity);

        final istanbulDistrict = istanbulDistrictsFixture.firstWhere(
          (d) => d.name == 'İSTANBUL',
        );

        await cubit.selectDistrict(istanbulDistrict);

        verify(
          () => locationStore.save(
            const SelectedLocation(
              cityId: '539',
              cityName: 'İstanbul',
              districtId: '9541',
              districtName: 'İstanbul',
            ),
          ),
        ).called(1);

        expect(cubit.state.saved, isTrue);
        await cubit.close();
      },
    );

    test('selectDistrict selectedCity null ise işlem yapmaz', () async {
      final cubit = LocationPickerCubit(api: api, locationStore: locationStore);
      const district = District(id: '1', name: 'TEST');

      await cubit.selectDistrict(district);

      verifyNever(() => locationStore.save(any()));
      await cubit.close();
    });

    test('selectDistrict hata durumunda errorMessage yayınlar', () async {
      when(
        () => api.fetchDistricts('539'),
      ).thenAnswer((_) async => istanbulDistrictsFixture);
      when(
        () => locationStore.save(any()),
      ).thenThrow(Exception('Kayıt hatası'));

      final cubit = LocationPickerCubit(api: api, locationStore: locationStore);
      await cubit.selectCity(istanbulCity);

      final basaksehir = istanbulDistrictsFixture.firstWhere(
        (d) => d.name == 'BAŞAKŞEHİR',
      );

      await cubit.selectDistrict(basaksehir);

      expect(
        cubit.state.errorMessage,
        'Konum kaydedilemedi. İnternet bağlantınızı kontrol edin.',
      );
      await cubit.close();
    });

    test('backToCities aramayı temizler ve cities adımına döner', () async {
      when(
        () => api.fetchDistricts('539'),
      ).thenAnswer((_) async => istanbulDistrictsFixture);
      final cubit = LocationPickerCubit(api: api, locationStore: locationStore);
      await cubit.selectCity(istanbulCity);
      cubit
        ..search('başak')
        ..backToCities();

      expect(cubit.state.step, LocationPickerStep.cities);
      expect(cubit.state.selectedCity, isNull);
      expect(cubit.state.query, '');
      expect(cubit.state.districts, isEmpty);
      await cubit.close();
    });

    test('search iller adımında visibleCities listesini süzer', () async {
      when(api.fetchCities).thenAnswer((_) async => citiesFixture);
      final cubit = LocationPickerCubit(api: api, locationStore: locationStore);
      await cubit.loadCities();

      expect(cubit.visibleCities.length, 81);

      cubit.search('istan');
      expect(
        cubit.visibleCities.map((c) => c.name).toList(),
        ['İSTANBUL'],
      );

      cubit.search('');
      expect(cubit.visibleCities.length, 81);
      await cubit.close();
    });

    test('loadCities cubit kapalıysa emit yapmaz', () async {
      when(api.fetchCities).thenAnswer((_) async => citiesFixture);
      final cubit = LocationPickerCubit(api: api, locationStore: locationStore);
      final future = cubit.loadCities();
      await cubit.close();
      await future;
      expect(cubit.isClosed, isTrue);
    });

    test('loadCities hata durumunda cubit kapalıysa emit yapmaz', () async {
      when(api.fetchCities).thenThrow(Exception('Ağ hatası'));
      final cubit = LocationPickerCubit(api: api, locationStore: locationStore);
      final future = cubit.loadCities();
      await cubit.close();
      await future;
      expect(cubit.isClosed, isTrue);
    });

    test('selectCity cubit kapalıysa emit yapmaz', () async {
      when(
        () => api.fetchDistricts('539'),
      ).thenAnswer((_) async => istanbulDistrictsFixture);
      final cubit = LocationPickerCubit(api: api, locationStore: locationStore);
      final future = cubit.selectCity(istanbulCity);
      await cubit.close();
      await future;
      expect(cubit.isClosed, isTrue);
    });

    test('selectCity hata durumunda cubit kapalıysa emit yapmaz', () async {
      when(
        () => api.fetchDistricts('539'),
      ).thenThrow(Exception('Ağ hatası'));
      final cubit = LocationPickerCubit(api: api, locationStore: locationStore);
      final future = cubit.selectCity(istanbulCity);
      await cubit.close();
      await future;
      expect(cubit.isClosed, isTrue);
    });

    test('selectDistrict cubit kapalıysa emit yapmaz', () async {
      when(
        () => api.fetchDistricts('539'),
      ).thenAnswer((_) async => istanbulDistrictsFixture);
      when(() => locationStore.save(any())).thenAnswer((_) async {});
      final cubit = LocationPickerCubit(api: api, locationStore: locationStore);
      await cubit.selectCity(istanbulCity);
      final district = istanbulDistrictsFixture.first;
      final future = cubit.selectDistrict(district);
      await cubit.close();
      await future;
      expect(cubit.isClosed, isTrue);
    });

    test('selectDistrict hata durumunda cubit kapalıysa emit yapmaz', () async {
      when(
        () => api.fetchDistricts('539'),
      ).thenAnswer((_) async => istanbulDistrictsFixture);
      when(() => locationStore.save(any())).thenThrow(Exception('Hata'));
      final cubit = LocationPickerCubit(api: api, locationStore: locationStore);
      await cubit.selectCity(istanbulCity);
      final district = istanbulDistrictsFixture.first;
      final future = cubit.selectDistrict(district);
      await cubit.close();
      await future;
      expect(cubit.isClosed, isTrue);
    });

    test('isCenterDistrict selectedCity null ise false döner', () {
      const state = LocationPickerState();
      expect(
        state.isCenterDistrict(const District(id: '1', name: 'A')),
        isFalse,
      );
    });

    test('isCenterDistrict MERKEZ adli ilce icin true doner', () {
      const state = LocationPickerState(
        selectedCity: City(id: '1', name: 'AGRI'),
      );
      expect(
        state.isCenterDistrict(const District(id: '2', name: 'MERKEZ')),
        isTrue,
      );
    });

    test('LocationPickerState copyWith ve props dogru calisir', () {
      const state = LocationPickerState();
      final updated = state.copyWith(
        step: LocationPickerStep.districts,
        cities: [istanbulCity],
        districts: [const District(id: '1', name: 'KARTAL')],
        selectedCity: istanbulCity,
        query: 'ist',
        loading: true,
        errorMessage: 'hata',
        saved: true,
      );
      expect(updated.step, LocationPickerStep.districts);
      expect(updated.cities.length, 1);
      expect(updated.districts.length, 1);
      expect(updated.selectedCity, istanbulCity);
      expect(updated.query, 'ist');
      expect(updated.loading, isTrue);
      expect(updated.errorMessage, 'hata');
      expect(updated.saved, isTrue);
      expect(updated.props.length, 8);

      final cleared = updated.copyWith(
        clearSelectedCity: true,
        clearErrorMessage: true,
      );
      expect(cleared.selectedCity, isNull);
      expect(cleared.errorMessage, isNull);
    });
  });
}
