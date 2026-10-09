// Seçili konum bilgilerini kalıcı depolayan ve yöneten depo sınıfı.

import 'dart:convert';

import 'package:vakit/location/models/selected_location.dart';
import 'package:vakit/shared/storage/key_value_store.dart';

class LocationStore {
  const LocationStore(this._store);

  static const String selectedLocationKey = 'selected_location';

  final KeyValueStore _store;

  Future<SelectedLocation?> load() async {
    final raw = await _store.getString(selectedLocationKey);
    if (raw == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('JSON nesnesi bekleniyor.');
      }
      return SelectedLocation.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      await _store.remove(selectedLocationKey);
      return null;
    }
  }

  Future<void> save(SelectedLocation location) async {
    final raw = jsonEncode(location.toJson());
    await _store.setString(selectedLocationKey, raw);
  }

  Future<void> clear() async {
    await _store.remove(selectedLocationKey);
  }
}
