import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import '../../core/assets/game_assets.dart';
import 'game_audio.dart';

/// [GameAudio]'nun `flame_audio` uzerindeki gercek uygulamasi.
///
/// Ses seviyeleri burada sabitlenir: ates sesi cok sik caldigi icin kisik,
/// patlama daha belirgin. Bu degerler oyun hissini etkiler, tek yerde durmasi
/// ayarlamayi kolaylastirir.
class FlameGameAudio implements GameAudio {
  bool _muted = false;

  /// Sik calan sesler icin OYNATICI HAVUZU.
  ///
  /// NEDEN: `FlameAudio.play` her cagrida YENI bir native oynatici kurar.
  /// Ates sesi saniyede ~4,5 kez caliyor, yani saniyede 4,5 oynatici
  /// hazirlanip atiliyordu. Emulatorde bu, `audioplayers`in 30 saniyelik
  /// hazirlanma zaman asimina takildi ve release derlemesinde loglara
  /// yakalanmayan hata olarak dustu:
  ///
  ///   TimeoutException after 0:00:30 : Future not completed
  ///   AudioPlayer._completePrepared (audioplayers/src/audioplayer.dart:372)
  ///
  /// `AudioPool` onceden hazirlanmis oynaticilari yeniden kullanir; dokumani
  /// bunu "extremely quick firing, repetitive or simultaneous sounds" durumu
  /// icin onerir. Mermiler icin nesne havuzu kullanip ses oynaticilarini her
  /// seferinde yeniden kurmak tutarsizdi.
  ///
  /// AudioPool (audioplayers — src/audio_pool.dart)
  AudioPool? _shootPool;
  AudioPool? _explosionPool;

  @override
  bool get isMuted => _muted;

  /// Ses dosyalarini disk/agdan onbellege alir, ses baglamini yapilandirir ve
  /// oynatici havuzlarini ONCEDEN ISITIR.
  ///
  /// Bu yapilmazsa ilk `play` cagrisinda yukleme gecikmesi olusur ve ses
  /// oynanistan geride kalir.
  /// AudioCache.loadAll (audioplayers — src/audio_cache.dart)
  @override
  Future<void> preload() async {
    await _configureAudioFocus();
    await FlameAudio.audioCache.loadAll(GameAssets.audio);

    // maxPlayers degerleri seslerin UST USTE BINME sayisina gore secildi:
    // ates sesi kisa ve 0,22 sn arayla caliyor, bu yuzden en fazla 4 tanesi
    // ayni anda duyulabilir. Patlama daha uzun ama daha seyrek.
    _shootPool = await FlameAudio.createPool(
      GameAssets.shootSound,
      minPlayers: 2,
      maxPlayers: 4,
    );
    _explosionPool = await FlameAudio.createPool(
      GameAssets.explosionSound,
      minPlayers: 1,
      maxPlayers: 3,
    );
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
  void playShoot() => _playPooled(_shootPool, 0.30);

  @override
  void playExplosion() => _playPooled(_explosionPool, 0.55);

  /// Elmas sesi HAVUZLANMAZ: 3,5-7 saniyede bir caliyor, ust uste binmesi
  /// pratikte imkansiz. Havuz yalnizca gercekten sik calan sesler icin
  /// anlamlidir -- ayni gerekce `PickupComponent`in havuzlanmamasinda da var.
  @override
  void playPickup() => _playOneShot(GameAssets.pickupSound, 0.45);

  void _playPooled(AudioPool? pool, double volume) {
    // Havuz `preload` icinde kurulur. Henuz kurulmadiysa (ornegin `preload`
    // basarisiz olduysa) ses sessizce atlanir, oyun durmaz.
    if (_muted || pool == null) {
      return;
    }
    _ignoreFailure(pool.start(volume: volume));
  }

  void _playOneShot(String asset, double volume) {
    if (_muted) {
      return;
    }
    _ignoreFailure(FlameAudio.play(asset, volume: volume));
  }

  /// Ses oynatma hatasini YUTAR ama SESSIZCE KAYBETMEZ.
  ///
  /// Sonucu beklememek yeterli degil: beklenmeyen bir `Future` hata verirse
  /// Flutter'in zone yakalayicisina duser ve loglara "Unhandled Exception"
  /// olarak yazilir. Bu gercekten yasandi (bkz. [_shootPool]). Bir sesin
  /// calmamasi oyunu durdurmayi hak eden bir hata degil, ama loglari
  /// kirletmesi de dogru degil; bu yuzden burada acikca yakalanir.
  void _ignoreFailure(Future<void> playback) {
    playback.catchError((Object error, StackTrace stackTrace) {
      // Uretimde sessiz, gelistirmede gorunur.
      if (kDebugMode) {
        debugPrint('[audio] ses calinamadi: $error');
      }
    });
  }
}
