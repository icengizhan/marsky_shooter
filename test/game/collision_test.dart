import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/core/config/game_config.dart';
import 'package:marsky_shooter/game/components/enemy/enemy_component.dart';
import 'package:marsky_shooter/game/components/projectile/bullet_component.dart';
import 'package:marsky_shooter/game/marsky_game.dart';
import 'package:marsky_shooter/game/state/game_phase.dart';

import '../helpers/test_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Carpisma', () {
    testWithGame<MarskyGame>('mermi dusmani vurur: dusman olur, skor artar', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();

      // REGRESYON TESTI: mermi TAM OLARAK dusmanin merkezine konur, yani
      // kucuk mermi hitbox'i buyuk dusman dairesinin tamamen icinde kalir ve
      // hicbir KENAR kesismez. Hitbox'lar `isSolid: true` olmasaydi Flame bu
      // durumu carpisma saymaz ve isabet kaybolurdu.
      final EnemyComponent enemy = EnemyComponent(
        spawnPosition: Vector2(120, 200),
        velocity: Vector2.zero(),
      );
      await game.world.add(enemy);
      await game.world.add(BulletComponent(spawnPosition: Vector2(120, 200)));
      await game.ready();

      final int scoreBefore = game.score.points.value;

      // Carpisma taramasi `update` icinde calisir.
      game.update(0.001);
      await game.ready();

      expect(enemy.isDying, isTrue, reason: 'dusman isabet almali');
      expect(
        game.score.points.value,
        greaterThan(scoreBefore),
        reason: 'dusman olumu puan kazandirmali',
      );
    });

    testWithGame<MarskyGame>('oyuncu dusmana carparsa oyun biter ve motor durur', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();

      // Oyun ana menude baslar (case PDF §2.B); oynanisa gecilir.
      expect(game.phase.value, GamePhase.menu);
      game.startGame();
      expect(game.phase.value, GamePhase.playing);

      // Dusman dogrudan oyuncunun uzerine konur.
      final Vector2 playerPosition = game.playerOrNull!.position.clone();
      await game.world.add(
        EnemyComponent(spawnPosition: playerPosition, velocity: Vector2.zero()),
      );
      await game.ready();

      game.update(0.001);

      // Carpisma aninda henuz "oyun bitti" gelmez: olum animasyonu penceresi
      // boyunca motor calisir ki patlama ve sarsinti gorunebilsin.
      expect(game.phase.value, GamePhase.playing);
      expect(game.paused, isFalse, reason: 'efektler oynayabilmeli');
      expect(
        game.isPlaying,
        isFalse,
        reason: 'olum penceresinde oynanis mantigi durmus olmali',
      );

      advance(game, GameConfig.deathAnimationDuration + 0.1);

      expect(game.phase.value, GamePhase.gameOver);
      expect(game.paused, isTrue, reason: 'pauseEngine cagrilmis olmali');
    });

    testWithGame<MarskyGame>('startGame sahneyi temizler ve durumu sifirlar', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();

      await game.world.add(
        EnemyComponent(
          spawnPosition: Vector2(50, 50),
          velocity: Vector2.zero(),
        ),
      );
      await game.ready();
      game.score.addEnemyKill();
      killPlayerAndSettle(game);
      expect(game.phase.value, GamePhase.gameOver);

      game.startGame();
      await game.ready();

      expect(game.phase.value, GamePhase.playing);
      expect(game.score.points.value, 0);
      expect(game.paused, isFalse);
      expect(
        game.world.children.whereType<EnemyComponent>(),
        isEmpty,
        reason: 'onceki oyundan kalan dusman olmamali',
      );
    });
  });
}
