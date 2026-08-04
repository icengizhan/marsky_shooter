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
import 'components/pickup/pickup_component.dart';
import 'components/player/player_component.dart';
import 'components/projectile/bullet_component.dart';
import 'input/drag_input_component.dart';
import 'managers/enemy_spawner.dart';
import 'managers/interval_spawner.dart';
import 'managers/pickup_spawner.dart';
import 'state/game_overlays.dart';
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

  /// Oyunun bulundugu durum. Overlay'ler bunu takip ederek degisir.
  /// Oyun ana menude baslar (case PDF §2.B).
  final ValueNotifier<GamePhase> phase = ValueNotifier<GamePhase>(
    GamePhase.menu,
  );

  PlayerComponent? _player;

  /// Tum uretici'ler. Liste halinde tutulmasi, yeni bir uretici eklendiginde
  /// sifirlama kodunun degismesini onler.
  final List<IntervalSpawner> _spawners = <IntervalSpawner>[];

  /// Oyuncu henuz yuklenmemis olabilecegi icin nullable dondurulur.
  /// Spawner dusman yonunu hesaplamak icin bunu kullanir.
  PlayerComponent? get playerOrNull => _player;

  /// Component'ler "su an oynaniyor mu" sorusunu buradan sorar.
  /// Ates ve dusman olusturma yalnizca bu `true` iken calisir.
  bool get isPlaying => phase.value == GamePhase.playing;

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

    _spawners
      ..add(EnemySpawner())
      ..add(PickupSpawner());
    await world.addAll(_spawners);

    // Girdi yakalayici en son eklenir. Oyuncunun `nudge` metodu dogrudan
    // geri cagri (callback) olarak verilir -- girdi katmani oyuncunun ic
    // yapisini bilmez, yalnizca "su kadar otele" der.
    world.add(DragInputComponent(onPanDelta: player.nudge));

    // Durum degistikce dogru overlay gosterilir. Overlay yonetimi tek bir
    // yerde toplanir; her buton kendi basina overlay eklemeye/kaldirmaya
    // calissa tutarsiz durumlar (ornegin hem pause hem game over ekrani)
    // olusabilirdi.
    phase.addListener(_syncOverlays);
    _syncOverlays();
  }

  void _syncOverlays() {
    overlays.clear();
    switch (phase.value) {
      case GamePhase.menu:
        overlays.add(GameOverlays.mainMenu);
      case GamePhase.playing:
        overlays.add(GameOverlays.hud);
      case GamePhase.paused:
        // HUD gorunur kalir: oyuncu duraklatirken skorunu gormeye devam eder.
        overlays.add(GameOverlays.hud);
        overlays.add(GameOverlays.pause);
      case GamePhase.gameOver:
        overlays.add(GameOverlays.gameOver);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Skor yalnizca aktif oynanista artar; menude veya duraklatilmisken artmaz.
    if (isPlaying) {
      score.addSurvivalTime(dt);
    }
  }

  /// Ana menuden veya oyun bitti ekranindan yeni oyun baslatir.
  void startGame() {
    _resetScene();
    phase.value = GamePhase.playing;
    resumeEngine();
  }

  /// Oyunu birakip ana menuye doner.
  void goToMenu() {
    _resetScene();
    phase.value = GamePhase.menu;
    // Menude motor CALISIR: yildizlar kaymaya devam eder, menu olu gorunmez.
    // Ates ve spawn `isPlaying` uzerinden kapali oldugu icin oynanis islemez.
    resumeEngine();
  }

  /// Oyuncu bir dusmana carptiginda [PlayerComponent] tarafindan cagrilir.
  void handlePlayerHit() {
    // Ayni karede birden fazla dusmana carpilabilir; ilk carpismadan sonra
    // durum degistigi icin sonrakiler yok sayilir.
    if (!isPlaying) {
      return;
    }
    audio.playExplosion();
    phase.value = GamePhase.gameOver;
    pauseEngine();
  }

  /// Uygulama arka plana alindiginda cagrilir.
  ///
  /// Mobilde arama gelmesi veya uygulama degistirilmesi durumunda oyun arka
  /// planda calismaya devam ederse oyuncu goremedigi bir dusmana carpip haksiz
  /// yere olur. Yalnizca oynanis sirasinda etkilidir; menude cagrilirsa
  /// hicbir sey yapmaz.
  void pauseIfPlaying() {
    if (phase.value == GamePhase.playing) {
      togglePause();
    }
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

  /// Sistem geri tusu / geri jesti istegi.
  ///
  /// Geri tusu BIR KADEME YUKARI cikarir:
  /// `oynanis -> duraklat -> ana menu -> uygulamadan cikis`
  ///
  /// Neden boyle: geri tusu ele alinmazsa oyun ortasinda basildiginda uygulama
  /// kapanir ve skor kaybolur -- mobil bir oyunda kabul edilemez. Duraklatmada
  /// geri = "devam et" yapilsaydi oyuncu `oynanis <-> duraklat` arasinda
  /// sikisip kalir, geri tusuyla uygulamadan hic cikamazdi.
  ///
  /// `true` donerse cagiran taraf sistem cikisina izin verir.
  bool handleBackRequest() {
    switch (phase.value) {
      case GamePhase.playing:
        togglePause();
        return false;
      case GamePhase.paused:
        goToMenu();
        return false;
      case GamePhase.gameOver:
        goToMenu();
        return false;
      case GamePhase.menu:
        return true;
    }
  }

  /// Sahneyi bosaltir ve sayaclari sifirlar.
  void _resetScene() {
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
    for (final PickupComponent pickup in world.children
        .whereType<PickupComponent>()
        .toList(growable: false)) {
      pickup.removeFromParent();
    }

    _player?.resetToStart();
    for (final IntervalSpawner spawner in _spawners) {
      spawner.reset();
    }
    score.reset();
  }

  @override
  void onRemove() {
    // Dinleyici ve ValueNotifier'lar elle serbest birakilir; aksi halde
    // bellekte kalirlar (bellek sizintisi).
    phase.removeListener(_syncOverlays);
    score.dispose();
    phase.dispose();
    super.onRemove();
  }
}
