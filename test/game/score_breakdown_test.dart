import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/core/config/game_config.dart';
import 'package:marsky_shooter/game/marsky_game.dart';
import 'package:marsky_shooter/game/state/game_phase.dart';
import 'package:marsky_shooter/game/state/game_score.dart';

import '../helpers/test_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScoreBreakdown', () {
    test('kaynaklar ayri ayri sayilir ve toplam tutar', () {
      final GameScore score = GameScore();

      // 3 saniye hayatta kalma (0.25 x 12 = 3.0, kayan nokta hatasi yok)
      for (int i = 0; i < 12; i++) {
        score.addSurvivalTime(0.25);
      }
      score.addEnemyKill();
      score.addEnemyKill();
      score.addPickupCollected();

      final ScoreBreakdown b = score.breakdown;
      expect(b.survivalSeconds, 3);
      expect(b.enemiesDestroyed, 2);
      expect(b.pickupsCollected, 1);
      expect(
        b.total,
        (3 * GameConfig.scorePerSecond) +
            (2 * GameConfig.scorePerEnemyKilled) +
            (1 * GameConfig.scorePerPickupCollected),
      );
      // Dokum toplami, canli skorla ayni olmali.
      expect(b.total, score.points.value);
    });

    test('reset dokumu de sifirlar', () {
      final GameScore score = GameScore();
      score.addEnemyKill();
      score.addPickupCollected();
      score.addSurvivalTime(1.0);

      score.reset();

      final ScoreBreakdown b = score.breakdown;
      expect(b.survivalSeconds, 0);
      expect(b.enemiesDestroyed, 0);
      expect(b.pickupsCollected, 0);
      expect(b.total, 0);
    });
  });

  group('Uygulama arka plana alinma', () {
    testWithGame<MarskyGame>('oynanista duraklatir', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();

      game.pauseIfPlaying();

      expect(game.phase.value, GamePhase.paused);
      expect(game.paused, isTrue);
    });

    testWithGame<MarskyGame>('ana menude hicbir sey yapmaz', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();

      game.pauseIfPlaying();

      expect(game.phase.value, GamePhase.menu);
      expect(game.paused, isFalse, reason: 'menude motor durmamali');
    });

    testWithGame<MarskyGame>('oyun bitti ekraninda durumu bozmaz', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();
      killPlayerAndSettle(game);
      expect(game.phase.value, GamePhase.gameOver);

      game.pauseIfPlaying();

      expect(
        game.phase.value,
        GamePhase.gameOver,
        reason: 'oyun bitti ekrani duraklatmaya donmemeli',
      );
    });
  });
}
