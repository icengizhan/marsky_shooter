import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/core/config/game_config.dart';
import 'package:marsky_shooter/game/components/pickup/pickup_component.dart';
import 'package:marsky_shooter/game/components/player/player_component.dart';
import 'package:marsky_shooter/game/marsky_game.dart';
import 'package:marsky_shooter/game/state/game_phase.dart';

import '../helpers/test_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Toplanabilir nesne', () {
    testWithGame<MarskyGame>('oyuncuya temas edince toplanir ve puan verir', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();

      final PlayerComponent player = game.playerOrNull!;
      final int scoreBefore = game.score.points.value;

      // Nesne dogrudan oyuncunun uzerine konur.
      final PickupComponent pickup = PickupComponent(
        spawnPosition: player.position.clone(),
      );
      await game.world.add(pickup);
      await game.ready();

      game.update(0.001);
      await game.ready();

      expect(pickup.isCollected, isTrue);
      expect(
        game.score.points.value - scoreBefore,
        GameConfig.scorePerPickupCollected,
      );
    });

    testWithGame<MarskyGame>('toplanan nesne oyunu BITIRMEZ', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();

      await game.world.add(
        PickupComponent(spawnPosition: game.playerOrNull!.position.clone()),
      );
      await game.ready();
      game.update(0.001);

      expect(
        game.phase.value,
        GamePhase.playing,
        reason: 'nesne toplamak dusmana carpmak gibi olmamali',
      );
    });

    testWithGame<MarskyGame>('cift sayim olmaz (ayni nesne iki kez puan vermez)', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();

      final PickupComponent pickup = PickupComponent(
        spawnPosition: game.playerOrNull!.position.clone(),
      );
      await game.world.add(pickup);
      await game.ready();

      final int before = game.score.points.value;
      game.update(0.001);
      game.update(0.001);
      await game.ready();

      expect(
        game.score.points.value - before,
        GameConfig.scorePerPickupCollected,
      );
    });

    testWithGame<MarskyGame>('asagi iner ve ekran altinda temizlenir', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();

      final PickupComponent pickup = PickupComponent(
        spawnPosition: Vector2(60, GameConfig.designHeight - 40),
      );
      await game.world.add(pickup);
      await game.ready();

      final double startY = pickup.position.y;
      advance(game, 0.1);
      expect(pickup.position.y, greaterThan(startY), reason: 'asagi inmeli');

      advance(game, 2);
      await game.ready();

      expect(
        pickup.isMounted,
        isFalse,
        reason: 'ekran disina cikan nesne temizlenmeli',
      );
    });

    testWithGame<MarskyGame>('oynanista nesne olusur', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();

      // En uzun aralik 7 sn; 9 sn'de en az bir nesne olusmali.
      advance(game, 9);
      await game.ready();

      expect(game.world.children.whereType<PickupComponent>(), isNotEmpty);
    });

    testWithGame<MarskyGame>('ana menude nesne olusmaz', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      advance(game, 9);
      await game.ready();

      expect(game.world.children.whereType<PickupComponent>(), isEmpty);
    });
  });
}
