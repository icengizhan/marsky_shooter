import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/core/config/game_config.dart';
import 'package:marsky_shooter/game/components/enemy/enemy_component.dart';
import 'package:marsky_shooter/game/marsky_game.dart';

import '../helpers/test_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Yapilandirma dogrulamasi', () {
    test('GameConfig tutarli', () {
      // `isConsistent` icindeki assert'lerden biri basarisiz olursa bu test
      // patlar; yani yanlis bir denge ayari CI'da yakalanir.
      expect(GameConfig.isConsistent, isTrue);
    });
  });

  group('Eszamanli dusman ust siniri', () {
    testWithGame<
      MarskyGame
    >('sinir doluyken yeni dusman olusturulmaz', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();

      // Sahne sinira kadar doldurulur. Dusmanlar EKRANIN USTUNDE ve HAREKETSIZ:
      // boylece ne ekrandan cikip silinirler ne oyuncuya carpip oyunu bitirirler
      // ne de mermi menziline girerler (mermi y<0'da temizlenir). Yani sayim
      // test boyunca sabit kalir ve olcum kesin olur.
      for (int i = 0; i < GameConfig.maxConcurrentEnemies; i++) {
        await game.world.add(
          EnemyComponent(
            spawnPosition: Vector2(30 + (i * 3), -200),
            velocity: Vector2.zero(),
          ),
        );
      }
      await game.ready();

      expect(
        game.world.children.whereType<EnemyComponent>().length,
        GameConfig.maxConcurrentEnemies,
        reason: 'hazirlik: sahne tam sinirda olmali',
      );

      // Bu surede normalde ~10 spawn denemesi olurdu (aralik en fazla 1,4 sn).
      advance(game, 6);
      await game.ready();

      expect(
        game.world.children.whereType<EnemyComponent>().length,
        GameConfig.maxConcurrentEnemies,
        reason: 'sinir doluyken spawn ATLANMALI, sayim artmamali',
      );
    });

    testWithGame<MarskyGame>(
      'sinirin altinda yeniden dusman olusturulur',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();

        advance(game, 4);
        await game.ready();

        expect(
          game.world.children.whereType<EnemyComponent>(),
          isNotEmpty,
          reason: 'sinir dolu degilken spawn normal islemeli',
        );
        expect(
          game.world.children.whereType<EnemyComponent>().length,
          lessThanOrEqualTo(GameConfig.maxConcurrentEnemies),
        );
      },
    );
  });

  group('Oyun alani sinirlari', () {
    testWithGame<MarskyGame>(
      'yana savrulan dusman temizlenir',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();

        // Yalnizca YATAY hareket: alt sinira hic ulasmaz. Yan sinir kontrolu
        // olmasaydi bu dusman sonsuza kadar yasar ve bosuna `update` alirdi.
        final EnemyComponent drifting = EnemyComponent(
          spawnPosition: Vector2(GameConfig.designWidth - 20, 200),
          velocity: Vector2(400, 0),
        );
        await game.world.add(drifting);
        await game.ready();
        expect(drifting.isMounted, isTrue);

        advance(game, 2);
        await game.ready();

        expect(
          drifting.isMounted,
          isFalse,
          reason: 'ekranin sagindan cikan dusman agactan cikarilmali',
        );
      },
    );
  });
}
