/// Oyun seslerinin SOZLESMESI.
///
/// NEDEN SOYUTLAMA VAR:
/// 1. `FlameAudio` arka planda `path_provider` platform eklentisini kullanir.
///    Unit testte platform kanali olmadigi icin dogrudan cagri
///    `MissingPluginException` atar ve oyunun test edilmesini imkansiz kilar.
///    Bu arayuz sayesinde testler [SilentGameAudio] gecerek oyunu sessiz
///    ayaga kaldirir.
/// 2. Case PDF §3 "ses ayarları" gibi oyun disi state'leri istiyor. Sesin tek
///    bir kapidan gecmesi, mute ozelliginin tek yerden uygulanmasini saglar --
///    her `play` cagrisinin yanina `if (!muted)` yazmak gerekmez.
abstract interface class GameAudio {
  /// Ses dosyalarini onbellege alir. Oyun basinda BIR KEZ cagrilir.
  Future<void> preload();

  /// Sesin tamamen kapatilip acilmasi.
  void setMuted(bool muted);

  bool get isMuted;

  void playShoot();

  void playExplosion();

  void playPickup();
}

/// Hicbir ses cikarmayan uygulama.
///
/// Kullanim yerleri: unit/widget testleri (platform kanali yok) ve sesin
/// desteklenmedigi ortamlar. Null yerine bos bir nesne kullanmak
/// (Null Object deseni), cagri yerlerinde null kontrolu yapilmasini onler.
class SilentGameAudio implements GameAudio {
  bool _muted = true;

  @override
  bool get isMuted => _muted;

  @override
  Future<void> preload() async {}

  @override
  void setMuted(bool muted) => _muted = muted;

  @override
  void playShoot() {}

  @override
  void playExplosion() {}

  @override
  void playPickup() {}
}
