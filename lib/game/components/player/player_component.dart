import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/config/game_config.dart';
import '../../marsky_game.dart';
import '../enemy/enemy_component.dart';
import '../pickup/pickup_component.dart';
import '../projectile/bullet_component.dart';

/// Oyuncunun gemisi.
///
/// Sorumlulugu uc sey: hedef konuma yumusak sekilde yaklasmak, belirli arayla
/// ates etmek ve dusmanla carpismayi bildirmek. Girdiyi KENDISI toplamaz --
/// disaridan [nudge] cagrilir (bkz. `DragInputComponent`). Bu ayrim sayesinde
/// oyuncu, kontrol yonteminden bagimsizdir.
class PlayerComponent extends SpriteComponent
    with HasGameReference<MarskyGame>, CollisionCallbacks {
  PlayerComponent()
    : super(
        size: Vector2(GameConfig.playerWidth, GameConfig.playerHeight),
        anchor: Anchor.center,
        priority: 10,
      );

  /// Geminin yaklasmaya calistigi konum. Surukleme bunu oteler, gemi pesinden
  /// gelir. Dogrudan `position`i degistirmek yerine hedef kullanilmasi hareketi
  /// yumusatir ve titremeyi (jitter) onler.
  final Vector2 _target = Vector2.zero();

  double _fireCooldown = 0;

  /// Vurus sonrasi kalan dokunulmazlik suresi. Sifirdan buyukse gemi hasar
  /// almaz ve yanip soner.
  double _invulnerability = 0;

  /// Su an dokunulmaz mi? Carpisma bunu sorar.
  bool get isInvulnerable => _invulnerability > 0;

  /// Senkron `onLoad` (bilincli) -- gerekcesi `ExplosionComponent`'te anlatildi.
  @override
  void onLoad() {
    sprite = Sprite(game.images.fromCache(GameAssets.player));
    resetToStart();

    // Hitbox sprite'tan KUCUK (yaricap = genisligin %34'u): ucgen gemi
    // sprite'inin kose bosluklarinda "degmedim ama oldum" hissi olusmaz.
    // Oyun hissi acisindan oyuncu lehine hitbox standart bir tekniktir.
    //
    // CollisionType.active: oyuncu tarama baslatir, cunku dusmanlar passive.
    // isSolid: true -> tam kapsanma durumunda da carpisma algilanir
    // (oyuncu ve dusman yaricaplari yakin oldugu icin bu durum mumkundur).
    add(
      CircleHitbox(
        radius: size.x * 0.34,
        position: size / 2,
        anchor: Anchor.center,
        isSolid: true,
        collisionType: CollisionType.active,
      ),
    );
  }

  /// Hedefi [delta] kadar oteler ve oyun alani icinde tutar.
  void nudge(Vector2 delta) {
    // Menude/duraklatilmisken surukleme yok sayilir. Aksi halde duraklatma
    // sirasinda yapilan surukleme hedefi kaydirir ve devam edildiginde gemi
    // aniden ziplar.
    if (!game.isPlaying) {
      return;
    }
    _target.add(delta);
    _clampTargetToScreen();
  }

  /// Gemiyi baslangic konumuna dondurur (yeniden baslatma icin).
  void resetToStart() {
    position = Vector2(
      GameConfig.designWidth / 2,
      GameConfig.designHeight - GameConfig.playerBottomMargin,
    );
    _target.setFrom(position);
    _fireCooldown = 0;
    _invulnerability = 0;
    // Olum aninda gizlenmis veya yanip sonerken yarim saydam kalmis olabilir.
    opacity = 1;
  }

  /// Vurus alindi: kisa bir dokunulmazlik penceresi baslatir.
  ///
  /// Pencere olmadan oyuncu bir dusman kumesinin icinde tum canlarini tek
  /// karede kaybeder ve ne oldugunu anlamaz.
  void startInvulnerability() {
    _invulnerability = GameConfig.invulnerabilityDuration;
  }

  /// Olum aninda gemiyi gizler.
  ///
  /// Component agactan CIKARILMIYOR, yalnizca gorunmez yapiliyor: cikarilsa
  /// yeniden baslatmada tekrar eklenmesi ve baglantilarinin (girdi geri
  /// cagrisi, hitbox) yeniden kurulmasi gerekirdi. Gizlemek daha basit ve
  /// hatasiz.
  void hideForDeath() {
    // Dokunulmazlik sayaci SIFIRLANMALI. Aksi halde son candan once alinan
    // vurusun yanip sonme mantigi olum penceresinde de calismaya devam eder ve
    // `opacity`yi 1'e geri cekerek gizlemeyi bozar -- yani patlama efektinin
    // ortasinda olu gemi tekrar gorunur. Mevcut regresyon testi bunu yakaladi.
    _invulnerability = 0;
    opacity = 0;
  }

  void _clampTargetToScreen() {
    final double halfWidth = (size.x / 2) + GameConfig.playerEdgePadding;
    final double halfHeight = (size.y / 2) + GameConfig.playerEdgePadding;
    _target.x = _target.x.clamp(halfWidth, GameConfig.designWidth - halfWidth);
    _target.y = _target.y.clamp(
      halfHeight,
      GameConfig.designHeight - halfHeight,
    );
  }

  /// CollisionCallbacks.onCollisionStart (Flame — src/collisions/collision_callbacks.dart)
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is EnemyComponent) {
      // Dokunulmazlik penceresindeyken temas yok sayilir. Zaten olmekte olan
      // bir dusman da hasar vermez (ayni karede iki kez tetiklenmesin).
      if (isInvulnerable || other.isDying) {
        return;
      }

      // Carpan dusman YOK EDILIR. Yapilmazsa oyuncu dusmanin icinde kalir,
      // dokunulmazlik biter bitmez ayni dusman tekrar vurur ve oyuncu neden
      // ust uste can kaybettigini anlamaz. Puan verilmez: carpismak bir isabet
      // degil, bir hatadir.
      other.takeHit();

      // Oyuncu "ne olacagina" karar vermez, yalnizca olayi bildirir. Can
      // dusurme ve oyun bitirme karari kok sinifta. Bu ayrim sayesinde can
      // sistemi eklenirken bu sinifta yalnizca dokunulmazlik kontrolu degisti.
      game.handlePlayerHit();
      return;
    }

    if (other is PickupComponent && !other.isCollected) {
      other.collect();
      game.score.addPickupCollected();
      // Elmas artik yalnizca puan degil GUC veriyor: silah bir kademe yukselir.
      // Bu, yukari cikip elmasi almayi bir puan tercihi olmaktan cikarip
      // gercek bir yatirima donusturuyor -- oyunun tek risk/odul karari buydu.
      game.run.upgradeWeapon();
      game.audio.playPickup();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateInvulnerability(dt);
    _followTarget(dt);
    _updateFiring(dt);
  }

  /// Dokunulmazlik sayacini isletir ve gemiyi yanip sondurur.
  ///
  /// Yanip sonme bir efekt/animasyon component'i ile degil `opacity` uzerinden
  /// yapiliyor: efekt eklemek yeniden baslatmada temizlenmesi gereken ayri bir
  /// nesne olusturur. Burada durum tek sayida (`_invulnerability`) toplaniyor,
  /// `resetToStart` onu sifirlayinca gorunum de kendiliginden duzeliyor.
  void _updateInvulnerability(double dt) {
    if (_invulnerability <= 0) {
      return;
    }
    _invulnerability -= dt;
    if (_invulnerability <= 0) {
      _invulnerability = 0;
      opacity = 1;
      return;
    }
    // Kalan sureye gore aç/kapa: tam saydam yapilmiyor (0,35) cunku oyuncunun
    // gemisini tamamen kaybetmesi kontrolu zorlastirir.
    final int blink =
        (_invulnerability * GameConfig.invulnerabilityBlinksPerSecond).floor();
    opacity = blink.isEven ? 0.35 : 1.0;
  }

  void _followTarget(double dt) {
    // Ustel yumusatma (exponential smoothing), TAM FPS-bagimsiz bicimiyle.
    //
    // Yaygin yazim `t = hiz * dt` seklindedir ve yalnizca YAKLASIK dogrudur:
    // `hiz = 18` ile 60 FPS'te t = 0,30 cikarken 20 FPS'te t = 0,90 olur, yani
    // kare hizi dustugunde gemi hedefe cok daha sert yapisir -- oynanis hissi
    // cihaza gore degisir. `1 - exp(-hiz * dt)` ise ayni `hiz` degeri icin her
    // kare hizinda AYNI gecici tepkiyi verir (0,26 ve 0,63; bir saniye sonunda
    // kalan mesafe iki durumda da e^-18).
    //
    // clamp'e gerek kalmaz: `dt > 0` iken sonuc dogal olarak [0, 1) araligindadir,
    // bu yuzden kare atlamasinda bile hedefi asma (overshoot) olusamaz.
    final double t = 1 - exp(-GameConfig.playerFollowSpeed * dt);

    // `setValues` ile tek seferde yazilir. `position += (_target - position) * t`
    // yazimi her karede UC yeni `Vector2` tahsis ederdi (fark, olcekli fark ve
    // toplam); bu bicim sifir tahsisle ayni sonucu verir ve tek bildirim uretir.
    position.setValues(
      position.x + (_target.x - position.x) * t,
      position.y + (_target.y - position.y) * t,
    );
  }

  void _updateFiring(double dt) {
    // Ana menude gemi ates etmez.
    if (!game.isPlaying) {
      return;
    }
    _fireCooldown -= dt;
    if (_fireCooldown > 0) {
      return;
    }
    // Ates araligini SILAH SEVIYESI belirler; son seviyede kisalir.
    // Deger `RunState`ten okunuyor, burada tekrar hesaplanmiyor: silah
    // kurallari tek yerde dursun.
    _fireCooldown = game.run.fireCooldown;
    _fire();
  }

  /// Silah seviyesine gore bir veya birden fazla mermi atar.
  ///
  /// Yatay sapma listesi seviyeden TURETILIR, `if/else` zinciriyle yazilmaz:
  /// yeni bir seviye eklendiginde yalnizca [_spreadOffsets] degisir.
  void _fire() {
    for (final double offsetX in _spreadOffsets(game.run.bulletsPerShot)) {
      // Mermi HAVUZDAN alinir, `new` ile uretilmez: saniyede ~4,5 mermi
      // olustugu icin geri donusum tahsis/cop toplama yukunu ortadan kaldirir.
      final BulletComponent bullet = game.bulletPool.acquire()
        ..reset(
          spawnPosition: Vector2(position.x + offsetX, position.y - size.y / 2),
        );

      // Mermi oyuncunun DEGIL, oyuncunun ebeveyninin (dunyanin) cocugu olarak
      // eklenir. Oyuncunun cocugu olsaydi, oyuncu ile birlikte hareket eder ve
      // oyuncu yok edildiginde mermiler de aninda kaybolurdu.
      parent?.add(bullet);
    }

    // Ses mermi BASINA degil, ates basina bir kez calar: uc mermi icin uc ses
    // ust uste binerse tek bir gurultuye donusur ve seviye atlama duyulmaz.
    // Ses dogrudan FlameAudio'ya degil, oyunun ses kapisina gider; boylece
    // mute ayari ve testlerde sessiz mod tek yerden yonetilir.
    game.audio.playShoot();
  }

  /// [count] merminin merkeze gore yatay sapmalari.
  ///
  /// 1 -> tek merkez mermi
  /// 2 -> merkezin iki yaninda simetrik ikili
  /// 3 -> merkez + iki yan (yan mermiler daha genis acilir)
  static Iterable<double> _spreadOffsets(int count) {
    const double step = GameConfig.bulletSpreadOffset;
    return switch (count) {
      1 => const <double>[0],
      2 => const <double>[-step / 2, step / 2],
      _ => const <double>[-step, 0, step],
    };
  }
}
