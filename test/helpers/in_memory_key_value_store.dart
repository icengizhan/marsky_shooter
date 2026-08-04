import 'package:marsky_shooter/data/datasources/key_value_store.dart';

/// Bellekte tutan sahte kalici depo.
///
/// NEDEN: gercek `SharedPrefsKeyValueStore` platform kanali kullanir ve widget
/// testinde calismaz. Bu sahte depo `keyValueStoreProvider` uzerine binerek
/// TUM zinciri gercek koduyla test etmemizi saglar:
/// `Riverpod -> ScoreRepositoryImpl -> KeyValueStore`
/// Yalnizca en alttaki disk erisimi taklit edilir; repository mantigi gercektir.
class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore({this.readDelay = Duration.zero});

  /// Okumalara yapay gecikme. Gercek diskte okuma aninda bitmez; sifir
  /// gecikmeli sahte depo, "okuma ucustayken ekran kapandi" gibi yaris
  /// durumlarini GIZLER. Bu alan o yarislari test edilebilir kilar.
  final Duration readDelay;

  final Map<String, Object?> values = <String, Object?>{};

  Future<void> _waitReadDelay() async {
    if (readDelay > Duration.zero) {
      await Future<void>.delayed(readDelay);
    }
  }

  @override
  Future<int?> readInt(String key) async {
    await _waitReadDelay();
    return values[key] as int?;
  }

  @override
  Future<void> writeInt(String key, int value) async => values[key] = value;

  @override
  Future<String?> readString(String key) async {
    await _waitReadDelay();
    return values[key] as String?;
  }

  @override
  Future<void> writeString(String key, String value) async =>
      values[key] = value;

  @override
  Future<bool?> readBool(String key) async {
    await _waitReadDelay();
    return values[key] as bool?;
  }

  @override
  Future<void> writeBool(String key, bool value) async => values[key] = value;
}
