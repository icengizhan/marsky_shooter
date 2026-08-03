import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_store.dart';

/// [KeyValueStore]'un `shared_preferences` uzerindeki uygulamasi.
///
/// `SharedPreferencesAsync` kullaniliyor (eski `SharedPreferences.getInstance()`
/// degil): eski API tum degerleri bellekte onbellekler ve baska bir yerden
/// yazilan deger bayatlayabilir. Async API her cagriyi dogrudan platforma
/// sorar, bu yuzden tutarli okuma garantisi verir.
class SharedPrefsKeyValueStore implements KeyValueStore {
  SharedPrefsKeyValueStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<int?> readInt(String key) => _prefs.getInt(key);

  @override
  Future<void> writeInt(String key, int value) => _prefs.setInt(key, value);

  @override
  Future<String?> readString(String key) => _prefs.getString(key);

  @override
  Future<void> writeString(String key, String value) =>
      _prefs.setString(key, value);
}
