import 'package:flame/components.dart';

import '../../core/config/game_config.dart';
import '../components/enemy/enemy_component.dart';
import '../components/player/player_component.dart';
import 'difficulty_curve.dart';
import 'interval_spawner.dart';

/// Rastgele araliklarla dusman olusturur; aralik zamanla kisalir.
///
/// [IntervalSpawner]'dan sayac ve durum kontrolunu miras alir. Spawn
/// mantiginin `MarskyGame` icine yazilmamasi bilinclidir -- kok sinif yalnizca
/// kompozisyon yapar, davranis tasimaz.
class EnemySpawner extends IntervalSpawner {
  EnemySpawner({super.random});

  /// Zorluk egrisi gecen sureye gore araligi kisaltir (tabani vardir).
  @override
  double nextInterval() {
    final ({double min, double max}) range = DifficultyCurve.spawnIntervalRange(
      elapsed,
    );
    return randomBetween(range.min, range.max);
  }

  @override
  void spawnOne() {
    final PlayerComponent? player = game.playerOrNull;
    if (player == null) {
      return;
    }

    // Ekranin ustunde, yatayda rastgele bir noktadan olusur.
    final double halfWidth = GameConfig.enemyWidth / 2;
    final Vector2 spawnPosition = Vector2(
      halfWidth +
          (random.nextDouble() * (GameConfig.designWidth - (halfWidth * 2))),
      -GameConfig.enemyHeight,
    );

    // Yon: olusma anindaki oyuncu konumuna dogru birim vektor.
    // `normalize()` olmadan uzak spawn noktalari daha hizli inerdi.
    final Vector2 direction = (player.position - spawnPosition)..normalize();
    final double speed = randomBetween(
      GameConfig.enemySpeedMin,
      GameConfig.enemySpeedMax,
    );

    parent?.add(
      EnemyComponent(spawnPosition: spawnPosition, velocity: direction * speed),
    );
  }
}
