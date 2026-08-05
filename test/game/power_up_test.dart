import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/core/config/game_config.dart';
import 'package:marsky_shooter/game/components/enemy/enemy_component.dart';
import 'package:marsky_shooter/game/components/pickup/pickup_component.dart';
import 'package:marsky_shooter/game/components/projectile/bullet_component.dart';
import 'package:marsky_shooter/game/marsky_game.dart';
import 'package:marsky_shooter/game/state/game_phase.dart';

import '../helpers/test_game.dart';

/// GUC YUKSELTME VE CAN SISTEMININ OYUN ICINDEKI DAVRANISI.
///
/// `run_state_test.dart` kurallari saf mantik olarak sinar; bu dosya kurallarin
/// gercekten oyuna BAGLI oldugunu dogrular: elmas toplamak silahi yukseltiyor
/// mu, yukselen silah gercekten daha fazla mermi uretiyor mu, seviye atlamasi
/// uretimi duraklatiyor mu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Oyuncunun uzerine bir elmas koyup toplanmasini saglar.
  Future<void> collectPickup(MarskyGame game) async {
    await game.world.add(
      PickupComponent(spawnPosition: game.playerOrNull!.position.clone()),
    );
    await game.ready();
    game.update(0.001);
  }

  int bulletCount(MarskyGame game) =>
      game.world.children.whereType<BulletComponent>().length;

  group('Elmas silahi yukseltir', () {
    testWithGame<MarskyGame>(
      'elmas toplamak seviyeyi artirir',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();
        expect(game.run.weaponLevel.value, 1);

        await collectPickup(game);

        expect(game.run.weaponLevel.value, 2);
      },
    );

    testWithGame<MarskyGame>('elmas hem PUAN hem GUC verir', createSilentGame, (
      MarskyGame game,
    ) async {
      // Ikisi birlikte olmali: elmas puan vermeyi birakirsa oyun bitti
      // ekranindaki kirilim yalan soyler; guc vermezse yukari cikma riski
      // anlamsizlasir.
      await game.ready();
      game.startGame();
      final int before = game.score.points.value;

      await collectPickup(game);

      expect(
        game.score.points.value,
        before + GameConfig.scorePerPickupCollected,
      );
      expect(game.run.weaponLevel.value, 2);
    });

    testWithGame<MarskyGame>(
      'seviye 2de tek ateste IKI mermi cikar',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();
        await collectPickup(game);

        // ARTIS olculuyor, mutlak sayi degil. Mermileri silip sifirdan saymak
        // kirilgandi: `parent.add()` cagrisi kuyruga girdigi icin henuz mount
        // edilmemis bir mermi `children` icinde gorunmuyor, silinmiyor ve
        // sonraki `ready()` onu mount ederek sayimi bozuyordu.
        await game.ready();
        final int before = bulletCount(game);

        // Tam bir ates dongusu + IKI KARE pay. Pay sart: `advance` istenen
        // sureyi tam kare sayisina YUVARLIYOR, `cooldown + 0.001` istegi 13
        // kareye (0,2167 sn) inip 0,22 sn'lik aralige hic ulasmiyordu ve test
        // "hic ates edilmedi" diye kiriliyordu. Iki kare fazlasi tek atesi
        // garanti eder, ikinci atese yetmez.
        advance(game, game.run.fireCooldown + frameSeconds * 2);
        await game.ready();

        expect(
          bulletCount(game) - before,
          2,
          reason: 'seviye 2 tek ateste iki paralel mermi atmali',
        );
      },
    );
  });

  group('Can sistemi', () {
    testWithGame<MarskyGame>(
      'vurus silah seviyesini de dusurur',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();
        await collectPickup(game);
        expect(game.run.weaponLevel.value, 2);

        game.handlePlayerHit();

        expect(game.run.lives.value, GameConfig.playerMaxLives - 1);
        expect(
          game.run.weaponLevel.value,
          1,
          reason: 'vurulmak kazanilan gucun bir kismini geri almali',
        );
      },
    );

    testWithGame<MarskyGame>(
      'dokunulmazlik penceresi suresi dolunca biter',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();
        game.handlePlayerHit();
        expect(game.playerOrNull!.isInvulnerable, isTrue);

        advance(game, GameConfig.invulnerabilityDuration + 0.05);

        expect(game.playerOrNull!.isInvulnerable, isFalse);
        expect(
          game.playerOrNull!.opacity,
          1,
          reason: 'yanip sonme bitince gemi tam gorunur olmali',
        );
      },
    );

    testWithGame<MarskyGame>(
      'yeni oyun canlari ve silahi sifirlar',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();
        await collectPickup(game);
        game.handlePlayerHit();

        game.startGame();

        expect(game.run.lives.value, GameConfig.playerMaxLives);
        expect(game.run.weaponLevel.value, 1);
        expect(game.run.level.value, 1);
      },
    );
  });

  group('Seviye atlama', () {
    testWithGame<MarskyGame>(
      'zorluk adimi gecince banner gorunur ve uretim duraklar',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();
        expect(game.levelBanner.value, 0, reason: 'basta banner yok');
        expect(game.isSpawnPaused, isFalse);

        advance(game, GameConfig.difficultyStepSeconds + 0.1);

        expect(game.levelBanner.value, 2, reason: 'ikinci seviye gosterilmeli');
        expect(
          game.isSpawnPaused,
          isTrue,
          reason: 'oyuncu yeni tempoya hazirlanmak icin nefes almali',
        );
      },
    );

    testWithGame<MarskyGame>(
      'banner suresi dolunca kaybolur, nefes biter',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();
        advance(game, GameConfig.difficultyStepSeconds + 0.1);
        expect(game.levelBanner.value, 2);

        advance(game, GameConfig.levelBannerDuration + 0.1);

        expect(game.levelBanner.value, 0);
        expect(game.isSpawnPaused, isFalse);
      },
    );

    testWithGame<MarskyGame>(
      'nefes sirasinda dusman URETILMEZ',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();
        advance(game, GameConfig.difficultyStepSeconds + 0.1);
        await game.ready();

        // Nefes basladi. Sahnedeki dusmanlari temizleyip nefes boyunca yeni
        // dusman gelmedigini dogrula.
        for (final EnemyComponent e
            in game.world.children.whereType<EnemyComponent>().toList()) {
          e.removeFromParent();
        }
        await game.ready();
        expect(game.isSpawnPaused, isTrue);

        // Nefes suresinin biraz altinda ilerlet.
        advance(game, GameConfig.levelUpSpawnPause - 0.2);
        await game.ready();

        expect(
          game.world.children.whereType<EnemyComponent>(),
          isEmpty,
          reason: 'nefes bitmeden uretim baslamamali',
        );
      },
    );

    testWithGame<MarskyGame>(
      'oyun bitince seviye ve banner sifirlanir',
      createSilentGame,
      (MarskyGame game) async {
        await game.ready();
        game.startGame();
        advance(game, GameConfig.difficultyStepSeconds + 0.1);
        expect(game.run.level.value, 2);

        killPlayerAndSettle(game);
        expect(game.phase.value, GamePhase.gameOver);

        game.goToMenu();

        expect(game.run.level.value, 1);
        expect(game.levelBanner.value, 0);
      },
    );
  });
}
