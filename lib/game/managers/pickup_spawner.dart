import 'package:flame/components.dart';

import '../../core/config/game_config.dart';
import '../components/pickup/pickup_component.dart';
import 'interval_spawner.dart';

/// Toplanabilir nesneleri rastgele araliklarla olusturur.
///
/// [IntervalSpawner]'dan sayac ve durum kontrolunu miras alir; yalnizca
/// "ne kadar bekle" ve "ne olustur" sorularini cevaplar.
class PickupSpawner extends IntervalSpawner {
  PickupSpawner({super.random});

  /// Sabit aralik: zorluk egrisine BAGLI DEGIL. Odul zamanla siklassa oyun
  /// kolaylasirdi -- amaclanan tam tersi.
  @override
  double nextInterval() =>
      randomBetween(GameConfig.pickupIntervalMin, GameConfig.pickupIntervalMax);

  @override
  void spawnOne() {
    final double halfWidth = GameConfig.pickupWidth / 2;
    parent?.add(
      PickupComponent(
        spawnPosition: Vector2(
          halfWidth +
              (random.nextDouble() *
                  (GameConfig.designWidth - (halfWidth * 2))),
          -GameConfig.pickupHeight,
        ),
      ),
    );
  }
}
