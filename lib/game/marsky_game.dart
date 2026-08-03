import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';

import '../core/assets/game_assets.dart';
import '../core/config/game_config.dart';

/// Oyunun kok (root) sinifi.
///
/// Faz 4'te oyuncu, dusman, mermi ve arka plan component'leri buraya eklenecek;
/// bu sinif bir "kompozisyon koku" olarak kalacak -- oyun mantigi ICINE
/// yazilmayacak, ayri Component siniflarina dagitilacak (case PDF §3:
/// "Tüm oyun mantığı tek bir sınıfa yığılmamalıdır").
///
/// FlameGame (Flame — https://docs.flame-engine.org/latest/flame/game.html)
class MarskyGame extends FlameGame {
  /// FlameGame.backgroundColor() (Flame — src/game/game.dart)
  /// Tuvalin her karede temizlendigi renk.
  @override
  Color backgroundColor() => GameConfig.spaceColor;

  /// Oyun ayaga kalkarken BIR KEZ calisir.
  ///
  /// Tum sprite ve sesler burada onbellege alinir. Case PDF §3 bunu aciken
  /// istiyor: "Görsel (sprite) ve işitsel varlıklar oyun başlamadan önce
  /// önbelleğe (preload) alınmalı, bellek (memory) sızıntısı yaratacak tekrarlı
  /// yüklemelerden kaçınılmalıdır."
  ///
  /// Kritik nokta: component'ler ASLA kendi `onLoad()`'unda dosyadan yukleme
  /// yapmaz; `images.fromCache(...)` ile bu onbellekten okur. Aksi halde her
  /// dusman spawn'inda disk/ag okumasi yapilir ve oyun 60 FPS'te cokerdi.
  ///
  /// Images.loadAll (Flame — src/cache/images.dart)
  /// AudioCache.loadAll (audioplayers — src/audio_cache.dart)
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await images.loadAll(GameAssets.images);
    await FlameAudio.audioCache.loadAll(GameAssets.audio);
  }
}
