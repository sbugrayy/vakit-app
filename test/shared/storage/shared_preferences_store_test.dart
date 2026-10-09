// SharedPreferencesStore sınıfının temel okuma, yazma, silme ve kurucu
// işlevlerini doğrulayan birim testleri.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:vakit/shared/storage/key_value_store.dart';
import 'package:vakit/shared/storage/shared_preferences_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('SharedPreferencesStore', () {
    test('KeyValueStore arayüzünü uygular', () {
      final store = SharedPreferencesStore();
      expect(store, isA<KeyValueStore>());
    });

    test('olmayan anahtar null döner', () async {
      final store = SharedPreferencesStore();
      final value = await store.getString('non_existent');
      expect(value, isNull);
    });

    test('yazılan değer okunur ve silinir', () async {
      final store = SharedPreferencesStore();

      await store.setString('key1', 'value1');
      expect(await store.getString('key1'), equals('value1'));

      await store.remove('key1');
      expect(await store.getString('key1'), isNull);
    });

    test('özel SharedPreferencesAsync örneği ile çalışır', () async {
      final customAsync = SharedPreferencesAsync();
      final store = SharedPreferencesStore(customAsync);

      await store.setString('custom_key', 'custom_value');
      expect(await store.getString('custom_key'), equals('custom_value'));
    });
  });
}
