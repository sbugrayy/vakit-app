// Testlerde kalıcı depolamayı taklit eden bellek içi KeyValueStore uygulaması.

import 'package:vakit/shared/storage/key_value_store.dart';

class InMemoryStore implements KeyValueStore {
  InMemoryStore([Map<String, String>? initialValues])
    : _storage = Map<String, String>.of(initialValues ?? const {});

  final Map<String, String> _storage;

  Map<String, String> get values => Map.unmodifiable(_storage);

  @override
  Future<String?> getString(String key) async => _storage[key];

  @override
  Future<void> setString(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }
}
