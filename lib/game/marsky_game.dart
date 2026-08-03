import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../core/assets/game_assets.dart';
import '../core/config/game_config.dart';
import 'audio/flame_game_audio.dart';
import 'audio/game_audio.dart';
import 'components/background/starfield_background.dart';
import 'components/enemy/enemy_component.dart';
import 'components/player/player_component.dart';
import 'components/projectile/bullet_component.dart';
import 'input/drag_input_component.dart';
import 'managers/enemy_spawner.dart';
import 'state/game_phase.dart';
import 'state/game_score.dart';

/// Oyunun kok (root) sinifi.
///
/// Bu sinif bir KOMPOZISYON KOKUDUR: oyun mantigi tasimaz, yalnizca
/// component'leri kurar, durum gecislerini yonetir ve birbirine baglar.
/// Hareket, ates, spawn, zorluk egrisi, girdi, ses ve skor -- hepsi ayri
/// siniflarda. (case PDF §3: "Tüm oyun mantığı tek bir sınıfa yığılmamalıdır")
///
/// `HasCollisionDetection`: Flame'in yerlesik carpisma sistemi. Manuel
/// matematiksel kesisim hesabi YAZILMAZ (case PDF §3 bunu acikca yasakliyor).
///
/// FlameGame (Flame — https://docs.flame-engine.org/latest/flame/game.html)
class MarskyGame extends FlameGame with HasCollisionDetection {
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

  /// Anlik skor. HUD bunu `ValueListenableBuilder` ile dinler.
  final GameScore score = GameScore();

  /// Oyunun bulundugu durum. Overlay'ler bunu dinleyerek gorunur/gizlenir.
  final ValueNotifier<GamePhase> phase = ValueNotifier<GamePhase>(
    GamePhase.playing,
  );

  PlayerComponent? _player;
  EnemySpawner? _spawner;

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

    final EnemySpawner spawner = EnemySpawner();
    _spawner = spawner;
    world.add(spawner);

    // Girdi yakalayici en son eklenir. Oyuncunun `nudge` metodu dogrudan
    // geri cagri (callback) olarak verilir -- girdi katmani oyuncunun ic
    // yapisini bilmez, yalnizca "su kadar otele" der.
    world.add(DragInputComponent(onPanDelta: player.nudge));
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Skor yalnizca aktif oynanista artar; menude veya duraklatilmisken artmaz.
    if (phase.value == GamePhase.playing) {
      score.addSurvivalTime(dt);
    }
  }

  /// Oyuncu bir dusmana carptiginda [PlayerComponent] tarafindan cagrilir.
  void handlePlayerHit() {
    // Ayni karede birden fazla dusmana carpilabilir; ilk carpismadan sonra
    // durum degistigi icin sonrakiler yok sayilir.
    if (phase.value != GamePhase.playing) {
      return;
    }
    audio.playExplosion();
    phase.value = GamePhase.gameOver;
    pauseEngine();
  }

  /// Duraklat / devam et.
  void togglePause() {
    if (phase.value == GamePhase.playing) {
      phase.value = GamePhase.paused;
      // pauseEngine: `update` cagrilari tamamen durur, yani `dt` akmaz.
      // Yalnizca cizimi durdurmak yeterli olmazdi -- dusmanlar arka planda
      // hareket etmeye devam ederdi.
      pauseEngine();
    } else if (phase.value == GamePhase.paused) {
      phase.value = GamePhase.playing;
      resumeEngine();
    }
  }

  /// Oyunu bastan baslatir: sahneyi temizler, sayaclari sifirlar.
  void restart() {
    // Kalan dusman ve mermiler temizlenmezse yeni oyun, onceki oyunun
    // ekrandaki nesneleriyle baslar -- sik yapilan bir hata.
    for (final EnemyComponent enemy in world.children
        .whereType<EnemyComponent>()
        .toList(growable: false)) {
      enemy.removeFromParent();
    }
    for (final BulletComponent bullet in world.children
        .whereType<BulletComponent>()
        .toList(growable: false)) {
      bullet.removeFromParent();
    }

    _player?.resetToStart();
    _spawner?.reset();
    score.reset();
    phase.value = GamePhase.playing;
    resumeEngine();
  }

  @override
  void onRemove() {
    // ValueNotifier'lar elle serbest birakilir; aksi halde dinleyiciler
    // bellekte kalir (bellek sizintisi).
    score.dispose();
    phase.dispose();
    super.onRemove();
  }
}
