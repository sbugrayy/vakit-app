// SettingsStore birim testleri.

import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/settings/models/app_settings.dart';
import 'package:vakit/settings/repository/settings_store.dart';

import '../../helpers/in_memory_store.dart';

void main() {
  late InMemoryStore memoryStore;
  late SettingsStore store;

  setUp(() {
    memoryStore = InMemoryStore();
    store = SettingsStore(memoryStore);
  });

  group('SettingsStore', () {
    test('boş depoda varsayılan ayarlar döner', () async {
      final settings = await store.load();

      expect(settings.themePreference, equals(ThemePreference.system));
      expect(settings.notificationEnabled, isTrue);
    });

    test('kaydet ve oku gidiş dönüşü doğru çalışır', () async {
      const settings = AppSettings(
        themePreference: ThemePreference.dark,
        notificationEnabled: false,
      );

      await store.save(settings);
      final loaded = await store.load();

      expect(loaded, equals(settings));
      expect(memoryStore.values[SettingsStore.themeKey], equals('dark'));
      expect(
        memoryStore.values[SettingsStore.notificationEnabledKey],
        equals('false'),
      );
    });

    test('açık tema ve aktif bildirim doğru kaydedilir ve okunur', () async {
      const settings = AppSettings(
        themePreference: ThemePreference.light,
      );

      await store.save(settings);
      final loaded = await store.load();

      expect(loaded, equals(settings));
      expect(memoryStore.values[SettingsStore.themeKey], equals('light'));
      expect(
        memoryStore.values[SettingsStore.notificationEnabledKey],
        equals('true'),
      );
    });

    test('bozuk tema değeri system olarak yorumlanır', () async {
      await memoryStore.setString(SettingsStore.themeKey, 'invalid_value');

      final settings = await store.load();

      expect(settings.themePreference, equals(ThemePreference.system));
      expect(settings.notificationEnabled, isTrue);
    });

    test('bozuk bildirim değeri true olarak yorumlanır', () async {
      await memoryStore.setString(
        SettingsStore.notificationEnabledKey,
        'not_a_boolean',
      );

      final settings = await store.load();

      expect(settings.notificationEnabled, isTrue);
    });
  });
}
