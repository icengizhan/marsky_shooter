import '../../domain/repositories/settings_repository.dart';
import '../datasources/key_value_store.dart';
import '../datasources/storage_keys.dart';

/// [SettingsRepository] sozlesmesinin anahtar-deger deposu uzerindeki uygulamasi.
///
/// Depolama teknolojisini bilmez; yalnizca [KeyValueStore] arayuzunu bilir.
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._store);

  final KeyValueStore _store;

  @override
  Future<bool> readSoundEnabled() async {
    // Varsayilan `true`: ilk kurulumda ses acik olsun. Kararin burada olmasi
    // onemli -- sunum katmani "kayit yoksa ne olacak" sorusunu bilmemeli.
    final bool? stored = await _store.readBool(StorageKeys.soundEnabled);
    return stored ?? true;
  }

  @override
  Future<void> writeSoundEnabled(bool isEnabled) =>
      _store.writeBool(StorageKeys.soundEnabled, isEnabled);
}
