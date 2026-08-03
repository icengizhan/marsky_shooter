import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/config/game_config.dart';
import '../../marsky_game.dart';

/// Toplanabilir altin nesne.
///
/// Case PDF §2.A skorun "hayatta kalınan süreye **veya toplanan nesnelere**
/// bağlı olarak" artmasini istiyor; bu component ikinci kaynagi saglar.
///
/// Tasarim amaci risk/odul dengesi: nesne dusmanlardan yavas iner ama yatayda
/// rastgele bir noktada olusur, yani almak icin oyuncu guvenli konumundan
/// sapmak zorunda kalir.
class PickupComponent extends SpriteComponent
    with HasGameReference<MarskyGame> {
  PickupComponent({required Vector2 spawnPosition})
    : super(
        position: spawnPosition,
        size: Vector2(GameConfig.pickupWidth, GameConfig.pickupHeight),
        anchor: Anchor.center,
        priority: 4,
      );

  bool _isCollected = false;

  /// Ayni karede birden fazla temas olusursa cift puan verilmesini engeller.
  bool get isCollected => _isCollected;

  @override
  Future<void> onLoad() async {
    sprite = Sprite(game.images.fromCache(GameAssets.pickup));

    // CollisionType.passive: nesne kimseyi taramaz, yalnizca oyuncu tarafindan
    // bulunur. Oyuncunun hitbox'i `active` oldugu icin temas yakalanir.
    // isSolid: true -> kucuk bir hitbox tamamen icine girse de temas sayilir
    // (bkz. CLAUDE.md, hitbox kurali).
    await add(
      CircleHitbox(
        radius: size.x * 0.45,
        position: size / 2,
        anchor: Anchor.center,
        isSolid: true,
        collisionType: CollisionType.passive,
      ),
    );
  }

  /// Oyuncu temas ettiginde cagrilir.
  void collect() {
    if (_isCollected) {
      return;
    }
    _isCollected = true;
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // `dt` ile olcekleme -> FPS'ten bagimsiz hiz.
    position.y += GameConfig.pickupSpeed * dt;

    // Donme yalnizca gorseldir; daire hitbox donmeden etkilenmedigi icin
    // oynanisi degistirmez.
    angle += GameConfig.pickupRotationSpeed * dt;

    if (position.y - size.y > GameConfig.designHeight) {
      removeFromParent();
    }
  }
}
