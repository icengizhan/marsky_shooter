/// Kullanici ayarlari icin SOZLESME (arayuz). Uygulamasi `data/` katmanindadir.
///
/// NEDEN AYRI BIR REPOSITORY: ses ayari onceden dogrudan `KeyValueStore`
/// uzerinden okunup yaziliyordu, yani skorlar icin kullanilan repository
/// katmani ATLANIYORDU. Ayni projede iki farkli kalicilik yaklasimi olmasi
/// tutarsizdir; sunum katmani "hangi anahtarla, hangi tipte saklandigini"
/// bilmemelidir. Bu arayuzle her iki ozellik de ayni deseni kullanir.
///
/// Saf Dart: hicbir framework'u bilmez.
abstract interface class SettingsRepository {
  /// Ses acik mi. Hic kaydedilmemisse `true` (ilk kurulumda ses acik).
  Future<bool> readSoundEnabled();

  Future<void> writeSoundEnabled(bool isEnabled);
}
