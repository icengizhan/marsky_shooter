import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/config/game_config.dart';
import '../../marsky_game.dart';
import '../enemy/enemy_component.dart';

/// Oyuncunun ates ettigi mermi. Yukari dogru sabit hizla gider.
class BulletComponent extends SpriteComponent
    with HasGameReference<MarskyGame>, CollisionCallbacks {
  BulletComponent({required Vector2 spawnPosition})
    : super(
        position: spawnPosition,
        size: Vector2(GameConfig.bulletWidth, GameConfig.bulletHeight),
        anchor: Anchor.center,
        priority: 5,
      );

  @override
  Future<void> onLoad() async {
    // DIKKAT: burada dosyadan yukleme YAPILMAZ. Sprite, oyun basinda
    // doldurulan onbellekten okunur. Aksi halde her ates ediste disk/ag
    // okumasi olur ve oyun kasardi.
    sprite = Sprite(game.images.fromCache(GameAssets.bullet));

    // Mermi ince ve uzun oldugu icin dikdortgen hitbox dogru sekildir.
    // CollisionType.active: taramayi mermi baslatir, cunku hareket eden ve
    // isabet arayan taraf odur.
    await add(
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

    // Ekran disina cikan mermi agactan cikarilir. Yapilmazsa her ates edilen
    // mermi sonsuza kadar bellekte ve update dongusunde kalir (bellek sizintisi).
    if (position.y + size.y < 0) {
      removeFromParent();
    }
  }
}
