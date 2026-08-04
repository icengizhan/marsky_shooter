import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/core/config/game_config.dart';
import 'package:marsky_shooter/game/components/enemy/enemy_component.dart';
import 'package:marsky_shooter/game/components/player/player_component.dart';
import 'package:marsky_shooter/game/components/projectile/bullet_component.dart';
import 'package:marsky_shooter/game/marsky_game.dart';

import '../helpers/test_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dusman olusturma', () {
    testWithGame<MarskyGame>('oynanista dusman olusur', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();

      // En uzun spawn araligi 1.4 sn; 3 sn'de en az bir dusman olusmali.
      advance(game, 3);
      await game.ready();

      expect(game.world.children.whereType<EnemyComponent>(), isNotEmpty);
    });

    testWithGame<MarskyGame>(
      'dusman OYUNCUYA DOGRU hareket eder',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();
        advance(game, 3);
        await game.ready();

        final EnemyComponent enemy = game.world.children
            .whereType<EnemyComponent>()
            .first;

        // Dusman ekranin USTUNDE olusur, oyuncu ALTTA durur -> asagi inmeli.
        expect(
          enemy.velocity.y,
          greaterThan(0),
          reason: 'dusman oyuncuya dogru (asagi) inmeli',
        );

        // Hiz buyuklugu yapilandirmadaki araliga uymali.
        expect(
          enemy.velocity.length,
          greaterThanOrEqualTo(GameConfig.enemySpeedMin - 0.01),
        );
        expect(
          enemy.velocity.length,
          lessThanOrEqualTo(GameConfig.enemySpeedMax + 0.01),
        );
      },
    );

    testWithGame<MarskyGame>(
      'ekran altindan cikan dusman temizlenir',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();

        // Ekranin altina dogru hizli giden bir dusman.
        await game.world.add(
          EnemyComponent(
            spawnPosition: Vector2(240, GameConfig.designHeight - 10),
            velocity: Vector2(0, 600),
          ),
        );
        await game.ready();

        advance(game, 1);
        await game.ready();

        expect(
          game.world.children.whereType<EnemyComponent>().where(
            (EnemyComponent e) => e.velocity.y == 600,
          ),
          isEmpty,
          reason: 'ekran disina cikan dusman agactan cikarilmali',
        );
      },
    );
  });

  group('Surukleme kontrolu', () {
    testWithGame<MarskyGame>(
      'surukleme gemiyi hedefe dogru oteler',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();
        final PlayerComponent player = game.playerOrNull!;
        final double startX = player.position.x;

        player.nudge(Vector2(80, 0));
        advance(game, 1);

        expect(player.position.x, greaterThan(startX + 60));
      },
    );

    testWithGame<MarskyGame>(
      'takip hareketi kare hizindan BAGIMSIZ ayni sonucu verir',
      createSilentGame,
      (MarskyGame game) async {
        // Iddia: `1 - exp(-hiz * dt)` ustel yumusatmasi ayni SURE icinde ayni
        // mesafeyi kat eder, kac karede kat edildigi onemli degildir.
        //
        // Neden kisa bir sure (0,1 sn) olculur: bir saniye sonunda her iki kare
        // hizi da hedefe fiilen varmis olur ve test ayirt etme gucunu kaybeder.
        // Gecici tepki (transient) yalnizca hareketin basinda gorunur.
        //
        // Yaygin `t = hiz * dt` yazimi bu testi GECEMEZ: 60 FPS'te kalan mesafe
        // orani 0,7^6 = 0,118 iken 20 FPS'te 0,1^2 = 0,010 olur -- gemi yavas
        // cihazda hedefe on kat daha sert yapisir.
        const double travelSeconds = 0.1;
        await game.ready();
        final PlayerComponent player = game.playerOrNull!;

        // `startGame()` gemiyi baslangic konumuna ve hedefini kendi uzerine
        // sifirlar; iki kosu ayni noktadan baslar.
        Vector2 positionAfter(int fps) {
          game.startGame();
          player.nudge(Vector2(100, -100));
          advanceAtFps(game, travelSeconds, fps: fps);
          return player.position.clone();
        }

        final Vector2 at60 = positionAfter(60);
        final Vector2 at20 = positionAfter(20);

        // Kayan nokta biriktirme payi: yarim pikselden az fark kabul edilir.
        expect(
          (at60 - at20).length,
          lessThan(0.5),
          reason:
              '60 ve 20 FPS ayni sure sonunda ayni konumu vermeli; '
              'aksi halde oynanis hissi cihaza gore degisir '
              '(60 FPS: $at60, 20 FPS: $at20)',
        );
      },
    );

    testWithGame<MarskyGame>('gemi ekran disina cikamaz', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();
      final PlayerComponent player = game.playerOrNull!;

      // Asiri buyuk bir oteleme.
      player.nudge(Vector2(99999, 99999));
      advance(game, 2);

      expect(player.position.x, lessThan(GameConfig.designWidth));
      expect(player.position.y, lessThan(GameConfig.designHeight));

      player.nudge(Vector2(-99999, -99999));
      advance(game, 2);

      expect(player.position.x, greaterThan(0));
      expect(player.position.y, greaterThan(0));
    });

    testWithGame<MarskyGame>(
      'ana menude surukleme yok sayilir',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        final PlayerComponent player = game.playerOrNull!;
        final Vector2 before = player.position.clone();

        player.nudge(Vector2(120, -200));
        advance(game, 1);

        expect(player.position.x, closeTo(before.x, 0.01));
        expect(player.position.y, closeTo(before.y, 0.01));
      },
    );
  });

  group('Mermi', () {
    testWithGame<MarskyGame>(
      'mermi yukari gider ve ekran ustunde temizlenir',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();

        await game.world.add(BulletComponent(spawnPosition: Vector2(240, 40)));
        await game.ready();

        final BulletComponent bullet = game.world.children
            .whereType<BulletComponent>()
            .firstWhere((BulletComponent b) => b.position.y == 40);
        final double startY = bullet.position.y;

        advance(game, 0.05);
        expect(
          bullet.position.y,
          lessThan(startY),
          reason: 'mermi yukari gitmeli',
        );

        advance(game, 1);
        await game.ready();

        expect(
          bullet.isMounted,
          isFalse,
          reason: 'ekran ustunden cikan mermi temizlenmeli',
        );
      },
    );
  });
}
