import 'package:marsky_shooter/data/datasources/key_value_store.dart';

/// Bellekte tutan sahte kalici depo.
///
/// NEDEN: gercek `SharedPrefsKeyValueStore` platform kanali kullanir ve widget
/// testinde calismaz. Bu sahte depo `keyValueStoreProvider` uzerine binerek
/// TUM zinciri gercek koduyla test etmemizi saglar:
/// `Riverpod -> ScoreRepositoryImpl -> KeyValueStore`
/// Yalnizca en alttaki disk erisimi taklit edilir; repository mantigi gercektir.
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, Object?> values = <String, Object?>{};

  @override
  Future<int?> readInt(String key) async => values[key] as int?;

  @override
  Future<void> writeInt(String key, int value) async => values[key] = value;

  @override
  Future<String?> readString(String key) async => values[key] as String?;

  @override
  Future<void> writeString(String key, String value) async =>
      values[key] = value;

  @override
  Future<bool?> readBool(String key) async => values[key] as bool?;

  @override
  Future<void> writeBool(String key, bool value) async => values[key] = value;
}
