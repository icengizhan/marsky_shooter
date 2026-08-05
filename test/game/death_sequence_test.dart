import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/core/config/game_config.dart';
import 'package:marsky_shooter/game/components/effects/explosion_component.dart';
import 'package:marsky_shooter/game/components/enemy/enemy_component.dart';
import 'package:marsky_shooter/game/components/pickup/pickup_component.dart';
import 'package:marsky_shooter/game/marsky_game.dart';
import 'package:marsky_shooter/game/state/game_phase.dart';

import '../helpers/test_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gorsel geri bildirim', () {
    testWithGame<MarskyGame>(
      'vurulan dusman patlama birakir',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();

        final EnemyComponent enemy = EnemyComponent(
          spawnPosition: Vector2(100, 150),
          velocity: Vector2.zero(),
        );
        await game.world.add(enemy);
        await game.ready();

        enemy.takeHit();
        await game.ready();

        expect(
          game.world.children.whereType<ExplosionComponent>(),
          isNotEmpty,
          reason: 'isabet gorsel geri bildirim vermeli',
        );
      },
    );

    testWithGame<MarskyGame>(
      'patlama suresi bitince kendini agactan cikarir',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();

        final EnemyComponent enemy = EnemyComponent(
          spawnPosition: Vector2(100, 150),
          velocity: Vector2.zero(),
        );
        await game.world.add(enemy);
        await game.ready();
        enemy.takeHit();
        await game.ready();

        advance(game, GameConfig.explosionDuration + 0.2);
        await game.ready();

        expect(
          game.world.children.whereType<ExplosionComponent>(),
          isEmpty,
          reason: 'RemoveEffect calismali, yoksa patlamalar birikir (sizinti)',
        );
      },
    );

    testWithGame<MarskyGame>(
      'toplanan elmas parlama birakir',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();

        final PickupComponent pickup = PickupComponent(
          spawnPosition: Vector2(200, 300),
        );
        await game.world.add(pickup);
        await game.ready();

        pickup.collect();
        await game.ready();

        expect(game.world.children.whereType<ExplosionComponent>(), isNotEmpty);
      },
    );
  });

  group('Olum dizisi', () {
    testWithGame<MarskyGame>(
      'olum aninda patlama olusur ve gemi gizlenir',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();

        killPlayerIntoDeathWindow(game);
        await game.ready();

        expect(game.world.children.whereType<ExplosionComponent>(), isNotEmpty);
        expect(
          game.playerOrNull!.opacity,
          0,
          reason: 'olen gemi gorunmez olmali',
        );
      },
    );

    testWithGame<MarskyGame>(
      'olum penceresinde motor calisir ama oynanis durur',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();
        advance(game, 2);
        final int scoreAtDeath = game.score.points.value;

        killPlayerIntoDeathWindow(game);

        // Pencere ortasi: efektler oynayabilsin diye motor CALISIR...
        advance(game, GameConfig.deathAnimationDuration / 2);
        expect(game.phase.value, GamePhase.playing);
        expect(game.paused, isFalse, reason: 'efektler icin motor calismali');
        // ...ama oynanis mantigi durmus olmali.
        expect(game.isPlaying, isFalse);
        expect(
          game.score.points.value,
          scoreAtDeath,
          reason: 'oldukten sonra hayatta kalma puani islememeli',
        );
      },
    );

    testWithGame<MarskyGame>(
      'pencere bitince oyun bitti ekrani gelir ve motor durur',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();

        killPlayerAndSettle(game);

        expect(game.phase.value, GamePhase.gameOver);
        expect(game.paused, isTrue);
      },
    );

    testWithGame<MarskyGame>(
      'olum penceresinde duraklat butonu isi bozmaz',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();
        killPlayerIntoDeathWindow(game);

        // Olum animasyonu sirasinda duraklat denenirse gecis askida kalmamali.
        game.togglePause();
        expect(
          game.phase.value,
          GamePhase.playing,
          reason: 'olum penceresinde duraklatma yok sayilmali',
        );

        advance(game, GameConfig.deathAnimationDuration + 0.1);
        expect(game.phase.value, GamePhase.gameOver);
      },
    );

    testWithGame<
      MarskyGame
    >('ekran sarsintisi kamerayi baslangica geri getirir', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();
      final Vector2 cameraBefore = game.camera.viewfinder.position.clone();

      killPlayerIntoDeathWindow(game);
      advance(game, GameConfig.deathAnimationDuration + 0.3);

      // `alternate: true` sayesinde efekt ileri gidip GERI DONER. Tek yonlu bir
      // MoveEffect kullanilsa kamera kalici olarak kayar ve oyun alani ekranin
      // disina tasardi -- bu test onu yakalar.
      expect(game.camera.viewfinder.position.x, closeTo(cameraBefore.x, 0.01));
      expect(game.camera.viewfinder.position.y, closeTo(cameraBefore.y, 0.01));
    });

    testWithGame<MarskyGame>(
      'yeniden baslatma gemiyi tekrar gorunur yapar',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();
        killPlayerAndSettle(game);
        expect(game.playerOrNull!.opacity, 0);

        game.startGame();
        await game.ready();

        expect(
          game.playerOrNull!.opacity,
          1,
          reason: 'yeni oyunda gemi gorunur olmali',
        );
        expect(
          game.world.children.whereType<ExplosionComponent>(),
          isEmpty,
          reason: 'onceki oyunun patlamalari yeni oyuna sarkmamali',
        );
      },
    );
  });
}
