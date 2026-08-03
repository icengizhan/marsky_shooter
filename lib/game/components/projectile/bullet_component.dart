import 'package:flame/components.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/config/game_config.dart';
import '../../marsky_game.dart';

/// Oyuncunun ates ettigi mermi. Yukari dogru sabit hizla gider.
class BulletComponent extends SpriteComponent with HasGameReference<MarskyGame> {
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
