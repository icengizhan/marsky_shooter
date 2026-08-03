/// Basit anahtar-deger deposu sozlesmesi.
///
/// Neden `SharedPreferences`i dogrudan repository icinde kullanmiyoruz:
/// `SharedPreferences` bir Flutter eklentisidir ve testte platform kanali
/// (platform channel) taklidi gerektirir. Araya bu ince arayuzu koyunca
/// repository testleri `mocktail` ile tek satirda sahte depo alabilir --
/// hicbir Flutter binding'i kurmaya gerek kalmaz.
///
/// Bu dosya da saf Dart'tir.
abstract interface class KeyValueStore {
  Future<int?> readInt(String key);

  Future<void> writeInt(String key, int value);

  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);
}
