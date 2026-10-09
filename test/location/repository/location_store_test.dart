// LocationStore sınıfının kalıcı depolama işlemlerini (yükleme, kaydetme,
// temizleme ve bozuk veri kurtarma) InMemoryStore ile doğrulayan testler.

import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/location/models/selected_location.dart';
import 'package:vakit/location/repository/location_store.dart';

import '../../helpers/in_memory_store.dart';

void main() {
  group('LocationStore', () {
    const sampleLocation = SelectedLocation(
      cityId: '506',
      cityName: 'İstanbul',
      districtId: '9541',
      districtName: 'Kadıköy',
      latitude: 40.99,
      longitude: 29.02,
    );

    test('boşken load() null döner', () async {
      final store = InMemoryStore();
      final locationStore = LocationStore(store);

      final loaded = await locationStore.load();
      expect(loaded, isNull);
    });

    test('kaydedilen konum nesnesi load() ile aynen yüklenir', () async {
      final store = InMemoryStore();
      final locationStore = LocationStore(store);

      await locationStore.save(sampleLocation);
      final loaded = await locationStore.load();

      expect(loaded, equals(sampleLocation));
    });

    test('clear() depodaki seçili konum kaydını siler', () async {
      final store = InMemoryStore();
      final locationStore = LocationStore(store);

      await locationStore.save(sampleLocation);
      await locationStore.clear();

      final loaded = await locationStore.load();
      expect(loaded, isNull);
      expect(store.values[LocationStore.selectedLocationKey], isNull);
    });

    test(
      'bozuk JSON metninde load() null döner ve bozuk kaydı siler',
      () async {
        final store = InMemoryStore();
        final locationStore = LocationStore(store);

        await store.setString(
          LocationStore.selectedLocationKey,
          '{gecersiz_json',
        );

        final loaded = await locationStore.load();
        expect(loaded, isNull);
        expect(store.values[LocationStore.selectedLocationKey], isNull);
      },
    );

    test(
      'geçerli JSON ama eksik alan durumunda load() null döner ve kaydı siler',
      () async {
        final store = InMemoryStore();
        final locationStore = LocationStore(store);

        await store.setString(
          LocationStore.selectedLocationKey,
          '{"cityId": "506", "cityName": "İstanbul"}',
        );

        final loaded = await locationStore.load();
        expect(loaded, isNull);
        expect(store.values[LocationStore.selectedLocationKey], isNull);
      },
    );

    test(
      'JSON harita yerine liste içeriyorsa load() null döner ve kaydı siler',
      () async {
        final store = InMemoryStore();
        final locationStore = LocationStore(store);

        await store.setString(
          LocationStore.selectedLocationKey,
          '["liste", "verisi"]',
        );

        final loaded = await locationStore.load();
        expect(loaded, isNull);
        expect(store.values[LocationStore.selectedLocationKey], isNull);
      },
    );
  });
}
