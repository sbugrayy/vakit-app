// Kalıcı anahtar-değer depolama sözleşmesi. Testlerde bellek içi sahteyle
// ikame edilebilir soyutlama sağlar.

abstract class KeyValueStore {
  const KeyValueStore();

  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}
