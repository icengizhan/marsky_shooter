import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/config/game_config.dart';
import '../../marsky_game.dart';
import '../enemy/enemy_component.dart';
import '../play_area_bounds.dart';

/// Oyuncunun ates ettigi mermi. Yukari dogru sabit hizla gider.
///
/// GERI DONUSTURULUR: ekrandan cikan mermi silinmek yerine Flame'in
/// `ComponentPool`una doner ve sonraki ateste yeniden kullanilir (bkz.
/// `MarskyGame.bulletPool`). Bu yuzden [spawnPosition] zorunlu degildir --
/// havuz nesneyi parametresiz uretir, ardindan [reset] ile konumlandirir.
///
/// Havuza geri verme isini Flame kendisi yapar; burada `onRemove` gerekmez.
class BulletComponent extends SpriteComponent
    with HasGameReference<MarskyGame>, CollisionCallbacks {
  BulletComponent({Vector2? spawnPosition})
    : super(
        position: spawnPosition ?? Vector2.zero(),
        size: Vector2(GameConfig.bulletWidth, GameConfig.bulletHeight),
        anchor: Anchor.center,
        priority: 5,
      );

  /// Havuzdan alinan mermiyi yeni ates icin hazirlar.
  ///
  /// Yeniden kullanilan bir nesnede ONCEKI DURUM sizabilir; burada sifirlanmasi
  /// gereken her sey aciktan yazilir.
  void reset({required Vector2 spawnPosition}) {
    position.setFrom(spawnPosition);
  }

  /// Senkron `onLoad` (bilincli) -- gerekcesi `ExplosionComponent`'te anlatildi:
  /// asenkron `onLoad` yasam dongusu kuyrugunu geciktirir ve arkasindaki
  /// eklemeleri bekletir. Hitbox eklemek icin beklemeye gerek yoktur.
  @override
  void onLoad() {
    // DIKKAT: burada dosyadan yukleme YAPILMAZ. Sprite, oyun basinda
    // doldurulan onbellekten okunur. Aksi halde her ates ediste disk/ag
    // okumasi olur ve oyun kasardi.
    sprite = Sprite(game.images.fromCache(GameAssets.bullet));

    // Mermi ince ve uzun oldugu icin dikdortgen hitbox dogru sekildir.
    // CollisionType.active: taramayi mermi baslatir, cunku hareket eden ve
    // isabet arayan taraf odur.
    add(
      RectangleHitbox(
        size: size.clone(),
        position: Vector2.zero(),
        isSolid: true,
        collisionType: CollisionType.active,
      ),
    );
  }

  /// CollisionCallbacks.onCollisionStart (Flame — src/collisions/collision_callbacks.dart)
  ///
  /// [other] karsi HITBOX degil karsi COMPONENT'tir: Flame `other.hitboxParent`
  /// gecirir (bkz. src/collisions/hitboxes/shape_hitbox.dart:243). Bu yuzden
  /// dogrudan tip kontrolu yapilabilir.
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // Oyuncunun kendi mermisi oyuncuya zarar vermez: yalnizca dusman ilgilendirir.
    if (other is! EnemyComponent || other.isDying) {
      return;
    }

    other.takeHit();
    removeFromParent();
    game.score.addEnemyKill();
    game.audio.playExplosion();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // `dt` ile carpim ZORUNLU: aksi halde mermi hizi cihazin kare hizina (FPS)
    // bagli olur, 120 Hz telefonda 60 Hz telefonun iki kati hizli ucar.
    position.y -= GameConfig.bulletSpeed * dt;

    // Ekran disina cikan mermi agactan cikarilir (ve havuza doner). Yapilmazsa
    // her ates edilen mermi sonsuza kadar bellekte ve update dongusunde kalir.
    if (isAbovePlayArea) {
      removeFromParent();
    }
  }
}
