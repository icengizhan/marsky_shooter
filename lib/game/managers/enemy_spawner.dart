import 'dart:math';

import 'package:flame/components.dart';

import '../../core/config/game_config.dart';
import '../components/enemy/enemy_component.dart';
import '../components/player/player_component.dart';
import '../marsky_game.dart';
import 'difficulty_curve.dart';

/// Rastgele araliklarla dusman olusturur ve zorlugu zamanla artirir.
///
/// Kendisi bir [Component]'tir: Flame'in `update` dongusune dogal olarak
/// katilir ve oyun duraklatildiginda (pauseEngine) kendiliginde durur.
/// Spawn mantiginin `MarskyGame` icine yazilmamasi bilinclidir -- kok sinif
/// yalnizca kompozisyon yapar, davranis tasimaz.
class EnemySpawner extends Component with HasGameReference<MarskyGame> {
  /// [random] disaridan verilebilir: testte sabit tohumlu bir [Random]
  /// gecirilerek spawn davranisi deterministik hale getirilir.
  EnemySpawner({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Oyun basindan bu yana gecen sure. Zorluk egrisinin girdisi.
  double _elapsed = 0;

  /// Sonraki spawn'a kalan sure.
  double _countdown = 0;

  @override
  Future<void> onLoad() async {
    _countdown = _nextInterval();
  }

  /// Yeniden baslatmada sayaclari sifirlar.
  void reset() {
    _elapsed = 0;
    _countdown = _nextInterval();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _countdown -= dt;
    if (_countdown > 0) {
      return;
    }
    _countdown = _nextInterval();
    _spawnEnemy();
  }

  double _nextInterval() {
    final ({double min, double max}) range = DifficultyCurve.spawnIntervalRange(
      _elapsed,
    );
    return range.min + (_random.nextDouble() * (range.max - range.min));
  }

  void _spawnEnemy() {
    final PlayerComponent? player = game.playerOrNull;
    if (player == null) {
      return;
    }

    // Ekranin ustunde, yatayda rastgele bir noktadan olusur.
    final double halfWidth = GameConfig.enemyWidth / 2;
    final Vector2 spawnPosition = Vector2(
      halfWidth + (_random.nextDouble() * (GameConfig.designWidth - (halfWidth * 2))),
      -GameConfig.enemyHeight,
    );

    // Yon: olusma anindaki oyuncu konumuna dogru birim vektor.
    // `normalized()` olmadan uzak spawn noktalari daha hizli inerdi.
    final Vector2 direction = (player.position - spawnPosition)..normalize();
    final double speed =
        GameConfig.enemySpeedMin +
        (_random.nextDouble() *
            (GameConfig.enemySpeedMax - GameConfig.enemySpeedMin));

    parent?.add(
      EnemyComponent(
        spawnPosition: spawnPosition,
        velocity: direction * speed,
      ),
    );
  }
}
