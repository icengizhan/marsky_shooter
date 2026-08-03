import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../core/assets/game_assets.dart';
import '../core/config/game_config.dart';
import 'audio/flame_game_audio.dart';
import 'audio/game_audio.dart';
import 'components/background/starfield_background.dart';
import 'components/player/player_component.dart';
import 'input/drag_input_component.dart';
import 'managers/enemy_spawner.dart';

/// Oyunun kok (root) sinifi.
///
/// Bu sinif bir KOMPOZISYON KOKUDUR: oyun mantigi tasimaz, yalnizca
/// component'leri kurar ve birbirine baglar. Hareket, ates, spawn, zorluk
/// egrisi, girdi ve ses -- hepsi ayri siniflarda.
/// (case PDF §3: "Tüm oyun mantığı tek bir sınıfa yığılmamalıdır")
///
/// FlameGame (Flame — https://docs.flame-engine.org/latest/flame/game.html)
class MarskyGame extends FlameGame {
  /// [audio] disaridan verilebilir (bagimlilik enjeksiyonu): testler
  /// `SilentGameAudio` gecerek platform kanali olmadan oyunu ayaga kaldirir.
  /// Uretimde varsayilan olarak gercek `flame_audio` uygulamasi kullanilir.
  MarskyGame({GameAudio? audio})
    : audio = audio ?? FlameGameAudio(),
      super(
        // Sabit cozunurluklu kamera: oyun her ekran boyutunda AYNI oynanis
        // alanini gosterir. Aksi halde buyuk ekranda oyuncu daha fazla yer
        // gorur ve oyun kolaylasir -- yani ekran boyutu adaleti bozar.
        camera: CameraComponent.withFixedResolution(
          width: GameConfig.designWidth,
          height: GameConfig.designHeight,
        ),
      );

  /// Tum ses cagrilarinin gectigi tek kapi.
  final GameAudio audio;

  PlayerComponent? _player;

  /// Oyuncu henuz yuklenmemis olabilecegi icin nullable dondurulur.
  /// Spawner dusman yonunu hesaplamak icin bunu kullanir.
  PlayerComponent? get playerOrNull => _player;

  /// FlameGame.backgroundColor() (Flame — src/game/game.dart)
  @override
  Color backgroundColor() => GameConfig.spaceColor;

  /// Oyun ayaga kalkarken BIR KEZ calisir.
  ///
  /// Tum sprite ve sesler burada onbellege alinir. Case PDF §3 bunu aciken
  /// istiyor: "Görsel (sprite) ve işitsel varlıklar oyun başlamadan önce
  /// önbelleğe (preload) alınmalı, bellek (memory) sızıntısı yaratacak tekrarlı
  /// yüklemelerden kaçınılmalıdır."
  ///
  /// Images.loadAll (Flame — src/cache/images.dart)
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await images.loadAll(GameAssets.images);
    await audio.preload();

    // Dunya koordinatlarini (0,0) - (designWidth, designHeight) yapar.
    // Viewfinder varsayilani merkez hizalidir; o durumda dunya -240..240
    // araliginda olurdu ve tum konum hesaplari sezgisellikten cikardi.
    camera.viewfinder
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();

    world.add(await createStarfieldBackground(images));

    final PlayerComponent player = PlayerComponent();
    _player = player;
    world.add(player);

    world.add(EnemySpawner());

    // Girdi yakalayici en son eklenir. Oyuncunun `nudge` metodu dogrudan
    // geri cagri (callback) olarak verilir -- girdi katmani oyuncunun ic
    // yapisini bilmez, yalnizca "su kadar otele" der.
    world.add(DragInputComponent(onPanDelta: player.nudge));
  }
}
