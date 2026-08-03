import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/game/components/enemy/enemy_component.dart';
import 'package:marsky_shooter/game/components/projectile/bullet_component.dart';
import 'package:marsky_shooter/game/marsky_game.dart';
import 'package:marsky_shooter/game/state/game_overlays.dart';
import 'package:marsky_shooter/game/state/game_phase.dart';

import '../helpers/test_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Oyun durumlari', () {
    testWithGame<MarskyGame>('ana menude ates edilmez ve dusman olusmaz', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      expect(game.phase.value, GamePhase.menu);

      // 5 saniye beklenir: normalde bu surede birkac dusman olusur ve
      // ~20 mermi atilirdi.
      advance(game, 5);
      await game.ready();

      expect(
        game.world.children.whereType<EnemyComponent>(),
        isEmpty,
        reason: 'menude dusman olusmamali',
      );
      expect(
        game.world.children.whereType<BulletComponent>(),
        isEmpty,
        reason: 'menude ates edilmemeli',
      );
      expect(game.score.points.value, 0, reason: 'menude skor artmamali');
    });

    testWithGame<MarskyGame>('oynanista ates edilir ve dusman olusur', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();

      advance(game, 3);
      await game.ready();

      expect(
        game.world.children.whereType<BulletComponent>(),
        isNotEmpty,
        reason: 'otomatik ates calismali',
      );
      expect(game.score.points.value, greaterThan(0), reason: 'hayatta kalma puani islemeli');
    });

    testWithGame<MarskyGame>('duraklatma motoru durdurur, devam etmek suruyu geri getirir', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();
      expect(game.paused, isFalse);

      game.togglePause();
      expect(game.phase.value, GamePhase.paused);
      expect(game.paused, isTrue, reason: 'pauseEngine cagrilmali');

      game.togglePause();
      expect(game.phase.value, GamePhase.playing);
      expect(game.paused, isFalse, reason: 'resumeEngine cagrilmali');
    });

    testWithGame<MarskyGame>('duraklatilmisken skor artmaz', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();
      advance(game, 2);
      final int scoreBeforePause = game.score.points.value;

      game.togglePause();
      // Motor durmus olsa da `update` elle cagrilirsa skor artmamali:
      // koruma `phase` uzerinden, yalnizca motor durumuna guvenilmiyor.
      advance(game, 3);

      expect(game.score.points.value, scoreBeforePause);
    });

    testWithGame<MarskyGame>('goToMenu sahneyi temizler ve menuye doner', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();
      advance(game, 3);
      await game.ready();

      game.goToMenu();
      await game.ready();

      expect(game.phase.value, GamePhase.menu);
      expect(game.paused, isFalse, reason: 'menude yildizlar kaymaya devam etmeli');
      expect(game.world.children.whereType<EnemyComponent>(), isEmpty);
      expect(game.world.children.whereType<BulletComponent>(), isEmpty);
      expect(game.score.points.value, 0);
    });

    testWithGame<MarskyGame>('her durum icin dogru overlay aktif olur', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      expect(game.overlays.activeOverlays, <String>[GameOverlays.mainMenu]);

      game.startGame();
      expect(game.overlays.activeOverlays, <String>[GameOverlays.hud]);

      game.togglePause();
      expect(
        game.overlays.activeOverlays,
        containsAll(<String>[GameOverlays.hud, GameOverlays.pause]),
        reason: 'duraklatmada skor gorunur kalmali',
      );

      game.togglePause();
      game.handlePlayerHit();
      expect(game.overlays.activeOverlays, <String>[GameOverlays.gameOver]);
    });
  });
}
