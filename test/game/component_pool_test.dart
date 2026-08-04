import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/core/config/game_config.dart';
import 'package:marsky_shooter/game/components/enemy/enemy_component.dart';
import 'package:marsky_shooter/game/components/projectile/bullet_component.dart';
import 'package:marsky_shooter/game/marsky_game.dart';

import '../helpers/test_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Nesne havuzu', () {
    testWithGame<MarskyGame>(
      'mermiler yeniden kullanilir: uretilen nesne sayisi atis sayisindan cok az',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();

        // Her karede ekranda bulunan mermilerin KIMLIKLERI toplanir. Ayni nesne
        // yeniden kullanilirsa kimligi degismez, yani kume buyumez.
        //
        // Karelerin arasinda `await` ZORUNLU: Flame'in havuzu nesneyi
        // `component.removed` Future'i tamamlaninca geri verir. Senkron bir
        // dongude Future'lar tamamlanmaz ve havuz bos kalir -- olcum yanlis
        // cikar (bkz. `advanceAsync` aciklamasi).
        final Set<int> distinctBullets = <int>{};
        const double seconds = 12;
        final int frames = (seconds / frameSeconds).round();
        for (int i = 0; i < frames; i++) {
          game.update(frameSeconds);
          await Future<void>.delayed(Duration.zero);
          for (final BulletComponent bullet
              in game.world.children.whereType<BulletComponent>()) {
            distinctBullets.add(identityHashCode(bullet));
          }
        }
        await game.ready();

        final int shotsFired = (seconds / GameConfig.fireCooldown).floor();
        expect(
          shotsFired,
          greaterThan(40),
          reason:
              '12 saniyede ~54 mermi atilmali (olcumun anlamli olmasi icin)',
        );
        expect(
          distinctBullets.length,
          lessThan(shotsFired ~/ 3),
          reason:
              'havuz olmadan her atis YENI nesne uretirdi; '
              'kullanilan nesne sayisi atis sayisina yakin olmamali',
        );
      },
    );

    testWithGame<
      MarskyGame
    >('ekrandan cikan mermi havuza geri doner', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();

      expect(game.bulletPool.availableCount, 0);

      // Mermi ekrani ~1,5 saniyede gecer; 4 saniye sonra bir kismi donmus olur.
      advance(game, 4);
      await game.ready();

      expect(
        game.bulletPool.availableCount,
        greaterThan(0),
        reason: 'silinen mermi havuza geri verilmis olmali',
      );
    });

    testWithGame<MarskyGame>('havuz ust siniri asilmaz', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();

      advance(game, 60);
      await game.ready();

      expect(
        game.bulletPool.availableCount,
        lessThanOrEqualTo(GameConfig.bulletPoolMaxSize),
        reason: 'ust sinir bellek kullanimini ongorulebilir tutar',
      );
      expect(
        game.enemyPool.availableCount,
        lessThanOrEqualTo(GameConfig.enemyPoolMaxSize),
      );
    });

    testWithGame<MarskyGame>(
      'yeniden kullanilan dusman "olu" isaretli kalmaz',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();

        final EnemyComponent enemy = EnemyComponent(
          spawnPosition: Vector2(100, 100),
          velocity: Vector2.zero(),
        );
        await game.world.add(enemy);
        await game.ready();

        enemy.takeHit();
        expect(enemy.isDying, isTrue);

        // Havuzdan yeniden alinmis gibi sifirla.
        enemy.reset(
          spawnPosition: Vector2(200, 50),
          newVelocity: Vector2(0, 90),
        );

        expect(
          enemy.isDying,
          isFalse,
          reason:
              '"olu" bayragi temizlenmezse yeniden kullanilan dusman '
              'mermiyle vurulamaz ve oyun sessizce bozulur',
        );
        expect(enemy.position, Vector2(200, 50));
        expect(enemy.velocity, Vector2(0, 90));
      },
    );

    testWithGame<MarskyGame>(
      'yeniden baslatma havuzu bozmaz: yeni oyunda mermi uretilir',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();
        advance(game, 5);
        await game.ready();

        // Sahne temizlenirken tum mermiler havuza doner.
        game.startGame();
        await game.ready();
        expect(game.world.children.whereType<BulletComponent>(), isEmpty);

        // Havuzdan yeniden alinip sorunsuz eklenebilmeli (mount hatasi olmamali).
        advance(game, 2);
        await game.ready();

        expect(
          game.world.children.whereType<BulletComponent>(),
          isNotEmpty,
          reason: 'havuzdan alinan mermiler yeni oyunda da calismali',
        );
      },
    );
  });
}
