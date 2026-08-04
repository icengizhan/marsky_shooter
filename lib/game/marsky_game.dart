import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../core/assets/game_assets.dart';
import '../core/config/game_config.dart';
import 'audio/flame_game_audio.dart';
import 'audio/game_audio.dart';
import 'components/background/starfield_background.dart';
import 'components/effects/explosion_component.dart';
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
  /// [random] disaridan verilebilir: testler sabit tohumlu bir [Random]
  /// gecirerek dusman/elmas olusumunu DETERMINISTIK hale getirir. Tohumsuz
  /// `Random()` ile testler zaman zaman sansa bagli olarak kirilir (flaky) --
  /// bu gercekten yasandi: duraklatma testinde tesadufi bir isabet skoru
  /// artiriyordu.
  MarskyGame({GameAudio? audio, Random? random})
    : audio = audio ?? FlameGameAudio(),
      _random = random ?? Random(),
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

  /// Tum ureticiler bu ayni rastgele kaynagi paylasir; tek tohum tum oyunu
  /// tekrarlanabilir kilar.
  final Random _random;

  /// Anlik skor. HUD bunu `ValueListenableBuilder` ile dinler.
  final GameScore score = GameScore();

  /// Mermi geri donusum havuzu (object pool).
  ///
  /// NEDEN: mermi saniyede ~4,5 kez uretiliyor; bir dakikalik oyunda ~270
  /// nesne olusup cope gidiyor. Havuz, ekrandan cikan mermiyi silmek yerine
  /// kenara koyar ve sonraki ateste AYNI nesneyi yeniden kullanir; boylece
  /// tahsis ve cop toplama yuku kare suresinden calmaz.
  ///
  /// Flame'in HAZIR [ComponentPool]'u kullanilir, elle havuz YAZILMAZ.
  /// Flame'inki nesneyi otomatik geri alir ve bunu dogru sirayla yapar:
  /// `component.mounted` tamamlanmasini bekler, SONRA `component.removed`
  /// dinler. Elle yazilan bir havuzda en sinsi hata tam buradadir --
  /// `removeFromParent()` kuyruga alindigi icin nesne henuz sokulmemisken
  /// havuza konursa yeniden `add` edilir ve "zaten mount edilmis" hatasi olusur.
  ///
  /// ComponentPool (Flame — src/components/component_pool.dart)
  final ComponentPool<BulletComponent> bulletPool =
      ComponentPool<BulletComponent>(
        factory: BulletComponent.new,
        maxSize: GameConfig.bulletPoolMaxSize,
      );

  /// Dusman geri donusum havuzu.
  final ComponentPool<EnemyComponent> enemyPool = ComponentPool<EnemyComponent>(
    factory: EnemyComponent.new,
    maxSize: GameConfig.enemyPoolMaxSize,
  );

  // NOT: `PickupComponent` BILINCLI olarak havuzlanmaz. 3,5-7 saniyede bir
  // uretiliyor; kazanc olculemez seviyede kalir, karmasiklik ise gercek olur.
  // Havuz yalnizca gercekten sik uretilen nesneler icin anlamlidir.

  /// Oyunun bulundugu durum. Overlay'ler bunu takip ederek degisir.
  /// Oyun ana menude baslar (case PDF §2.B).
  final ValueNotifier<GamePhase> phase = ValueNotifier<GamePhase>(
    GamePhase.menu,
  );

  PlayerComponent? _player;

  /// Tum uretici'ler. Liste halinde tutulmasi, yeni bir uretici eklendiginde
  /// sifirlama kodunun degismesini onler.
  final List<IntervalSpawner> _spawners = <IntervalSpawner>[];

  /// Oyuncu oldu ama "oyun bitti" ekrani henuz gelmedi.
  ///
  /// Bu kisa pencere olmadan `pauseEngine()` carpisma aninda cagrilir ve
  /// patlama/sarsinti efektleri HIC gorunmez; ekran birden donar, oyuncu neden
  /// oldugunu anlamaz. Pencere boyunca oynanis mantigi (ates, spawn, skor)
  /// durur ama motor calismaya devam eder ki efektler oynayabilsin.
  bool _isDying = false;

  /// Olum animasyonunun bitmesine kalan sure.
  ///
  /// NEDEN `TimerComponent` DEGIL: Flame'in `TimerComponent`'inin `onLoad`'i
  /// asenkrondur (bkz. flame/src/components/timer_component.dart:48), yani
  /// agaca eklenmesi bir olay dongusu turu gerektirir. Testler kareleri
  /// senkron olarak ilerlettigi icin boyle bir component hic mount edilmez ve
  /// olum gecisi test edilemez hale gelir. Duz bir sayac hem test edilebilir
  /// hem de kodun geri kalaniyla (ates ve spawn sayaclari) tutarlidir.
  double _deathCountdown = 0;

  /// Oyuncu henuz yuklenmemis olabilecegi icin nullable dondurulur.
  /// Spawner dusman yonunu hesaplamak icin bunu kullanir.
  PlayerComponent? get playerOrNull => _player;

  /// Component'ler "su an oynaniyor mu" sorusunu buradan sorar.
  /// Ates, dusman olusturma ve skor yalnizca bu `true` iken isler.
  ///
  /// Olum animasyonu penceresinde `phase` hala `playing` oldugu halde bu
  /// `false` doner -- boylece oyuncu oldukten sonra skor artmaya devam etmez
  /// ve yeni dusman olusmaz.
  bool get isPlaying => phase.value == GamePhase.playing && !_isDying;

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
      ..add(EnemySpawner(random: _random))
      ..add(PickupSpawner(random: _random));
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

    // Olum animasyonu penceresi: efektler oynarken oynanis mantigi islemez.
    if (_isDying) {
      _deathCountdown -= dt;
      if (_deathCountdown <= 0) {
        _finishGameOver();
      }
      return;
    }

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
  ///
  /// Iki asamali: once olum animasyonu oynar (patlama + ekran sarsintisi),
  /// [GameConfig.deathAnimationDuration] sonra "oyun bitti" ekrani gelir.
  void handlePlayerHit() {
    // Ayni karede birden fazla dusmana carpilabilir; ilk carpismadan sonra
    // `isPlaying` false oldugu icin sonrakiler yok sayilir.
    if (!isPlaying) {
      return;
    }
    _isDying = true;
    _deathCountdown = GameConfig.deathAnimationDuration;
    audio.playExplosion();

    final PlayerComponent? player = _player;
    if (player != null) {
      world.add(
        ExplosionComponent(
          explosionPosition: player.position.clone(),
          explosionRadius: GameConfig.playerExplosionRadius,
          explosionColor: GameConfig.playerExplosionColor,
        ),
      );
      player.hideForDeath();
    }
    _shakeCamera();
    // Geri sayim `update` icinde isler; bkz. [_deathCountdown].
  }

  void _finishGameOver() {
    _isDying = false;
    _deathCountdown = 0;
    phase.value = GamePhase.gameOver;
    pauseEngine();
  }

  /// Kisa ekran sarsintisi.
  ///
  /// `alternate: true` kritik: efekt ileri gidip GERI DONER, bu yuzden kamera
  /// baslangic konumuna kendiliginden dogru gelir. Tek yonlu bir MoveEffect
  /// kullanilsa kamera kalici olarak kayardi ve oyun alani ekranin disina
  /// tasardi.
  void _shakeCamera() {
    camera.viewfinder.add(
      MoveEffect.by(
        Vector2(
          GameConfig.screenShakeOffset,
          -GameConfig.screenShakeOffset * 0.6,
        ),
        EffectController(
          duration: GameConfig.screenShakeStepDuration,
          alternate: true,
          repeatCount: GameConfig.screenShakeRepeatCount,
        ),
      ),
    );
  }

  /// Uygulama arka plana alindiginda cagrilir.
  ///
  /// Mobilde arama gelmesi veya uygulama degistirilmesi durumunda oyun arka
  /// planda calismaya devam ederse oyuncu goremedigi bir dusmana carpip haksiz
  /// yere olur. Yalnizca oynanis sirasinda etkilidir; menude cagrilirsa
  /// hicbir sey yapmaz.
  void pauseIfPlaying() {
    if (isPlaying) {
      togglePause();
    }
  }

  /// Duraklat / devam et.
  ///
  /// `isPlaying` kullanilir, `phase.value == playing` degil: olum animasyonu
  /// penceresinde `phase` hala `playing` oldugu icin duraklat butonuna
  /// basilabilirdi ve olum gecisi askida kalirdi.
  void togglePause() {
    if (isPlaying) {
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

  /// Dunyadaki [T] turundeki tum component'leri agactan cikarir.
  ///
  /// `toList()` zorunlu: `children` uzerinde gezinirken ayni koleksiyondan
  /// eleman cikarmak dolayli olarak degisiklik hatasina yol acabilir.
  void _removeAllFromWorld<T extends Component>() {
    for (final T component in world.children.whereType<T>().toList(
      growable: false,
    )) {
      component.removeFromParent();
    }
  }

  /// Sahneyi bosaltir ve sayaclari sifirlar.
  void _resetScene() {
    // Kalan nesneler temizlenmezse yeni oyun, onceki oyunun ekrandaki
    // nesneleriyle baslar -- sik yapilan bir hata.
    _removeAllFromWorld<EnemyComponent>();
    _removeAllFromWorld<BulletComponent>();
    _removeAllFromWorld<PickupComponent>();
    // Yarim kalmis patlamalar yeni oyuna sarkmasin.
    _removeAllFromWorld<ExplosionComponent>();

    _isDying = false;
    _deathCountdown = 0;
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
