import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/core/config/game_config.dart';
import 'package:marsky_shooter/game/state/game_score.dart';

void main() {
  group('GameScore', () {
    test('bir saniye dolmadan puan verilmez', () {
      final GameScore score = GameScore();
      // 0.25 ikili sistemde tam temsil edilir; kayan nokta hatasi olusmaz.
      score.addSurvivalTime(0.25);
      score.addSurvivalTime(0.25);
      score.addSurvivalTime(0.25);

      expect(score.points.value, 0);
    });

    test('tam saniyede hayatta kalma puani eklenir', () {
      final GameScore score = GameScore();
      for (int i = 0; i < 4; i++) {
        score.addSurvivalTime(0.25);
      }

      expect(score.points.value, GameConfig.scorePerSecond);
    });

    test('kesirli artik korunur, ikinci saniye de sayilir', () {
      final GameScore score = GameScore();
      // 8 x 0.25 = 2.0 saniye
      for (int i = 0; i < 8; i++) {
        score.addSurvivalTime(0.25);
      }

      expect(score.points.value, GameConfig.scorePerSecond * 2);
    });

    test('dusman olumu sabit puan ekler', () {
      final GameScore score = GameScore();
      score.addEnemyKill();
      score.addEnemyKill();

      expect(score.points.value, GameConfig.scorePerEnemyKilled * 2);
    });

    test('reset skoru ve kesirli artigi sifirlar', () {
      final GameScore score = GameScore();
      score.addSurvivalTime(0.75);
      score.addEnemyKill();
      score.reset();

      expect(score.points.value, 0);

      // Artik da sifirlandiysa, 0.25 daha eklemek puan getirmemeli.
      score.addSurvivalTime(0.25);
      expect(score.points.value, 0);
    });
  });
}
