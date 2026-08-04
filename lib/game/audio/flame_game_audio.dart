import 'package:flame_audio/flame_audio.dart';

import '../../core/assets/game_assets.dart';
import 'game_audio.dart';

/// [GameAudio]'nun `flame_audio` uzerindeki gercek uygulamasi.
///
/// Ses seviyeleri burada sabitlenir: ates sesi cok sik caldigi icin kisik,
/// patlama daha belirgin. Bu degerler oyun hissini etkiler, tek yerde durmasi
/// ayarlamayi kolaylastirir.
class FlameGameAudio implements GameAudio {
  bool _muted = false;

  @override
  bool get isMuted => _muted;

  /// Ses dosyalarini disk/agdan onbellege alir ve ses baglamini yapilandirir.
  ///
  /// Bu yapilmazsa ilk `play` cagrisinda yukleme gecikmesi olusur ve ses
  /// oynanistan geride kalir.
  /// AudioCache.loadAll (audioplayers — src/audio_cache.dart)
  @override
  Future<void> preload() async {
    await _configureAudioFocus();
    await FlameAudio.audioCache.loadAll(GameAssets.audio);
  }

  /// SES ODAGI ALINMAZ (`AndroidAudioFocus.none`).
  ///
  /// audioplayers'in varsayilani `AndroidAudioFocus.gain`: her ses icin sistemden
  /// ses odagi ISTER ve birakir. Emulator logu bunu dogruladi -- saniyede ~4,5
  /// kez `abandonAudioFocus` cagrisi:
  ///
  ///   MediaFocusControl: abandonAudioFocus() ... callingPack=com.marsky.marsky_shooter
  ///
  /// Somut sonucu: oyuncu muzik dinliyorsa HER MERMIDE muzigi kisilir/kesilir.
  /// Kisa oyun efektleri odak istememelidir; `none` ile efektler mevcut sesin
  /// UZERINE calar ve kullanicinin muzigi bozulmaz.
  ///
  /// AudioPlayer.global.setAudioContext (audioplayers — src/global_audio_scope.dart:48)
  Future<void> _configureAudioFocus() {
    return AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      ),
    );
  }

  @override
  void setMuted(bool muted) => _muted = muted;

  @override
  void playShoot() => _play(GameAssets.shootSound, 0.30);

  @override
  void playExplosion() => _play(GameAssets.explosionSound, 0.55);

  @override
  void playPickup() => _play(GameAssets.pickupSound, 0.45);

  void _play(String asset, double volume) {
    if (_muted) {
      return;
    }
    // Sonuc beklenmez: ses calmasi oynanisi bloklamamalidir. Bir sesin
    // calmamasi oyunu durdurmayi hak eden bir hata degildir.
    FlameAudio.play(asset, volume: volume);
  }
}
