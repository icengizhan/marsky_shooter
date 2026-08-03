import 'package:flame/components.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/config/game_config.dart';
import '../../marsky_game.dart';

/// Ekranin ustunde olusup OYUNCUYA DOGRU inen dusman.
///
/// Yon vektoru olusma aninda hesaplanip sabitlenir (dalis manevrasi gibi).
/// Her karede yeniden hedeflemek yerine bunun secilmesi bilinclidir:
/// (1) oyuncu kacabilir, yoksa dusman kacinilmaz sekilde takip eder ve oyun
/// adil olmaz, (2) davranis deterministik olur, testte dogrulanabilir.
class EnemyComponent extends SpriteComponent with HasGameReference<MarskyGame> {
  EnemyComponent({required Vector2 spawnPosition, required this.velocity})
    : super(
        position: spawnPosition,
        size: Vector2(GameConfig.enemyWidth, GameConfig.enemyHeight),
        anchor: Anchor.center,
        priority: 6,
      );

  /// Saniyedeki yer degistirme (piksel/saniye). Olusma aninda hesaplanir,
  /// sonra degismez. Test bu degeri okuyarak yonu dogrulayabilir.
  final Vector2 velocity;

  @override
  Future<void> onLoad() async {
    sprite = Sprite(game.images.fromCache(GameAssets.enemy));
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Hareket her zaman `dt` ile olceklenir -> FPS'ten bagimsiz hiz.
    position += velocity * dt;

    // Ekranin altindan cikan dusman temizlenir.
    if (position.y - size.y > GameConfig.designHeight) {
      removeFromParent();
    }
  }
}
