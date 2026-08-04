import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/game/marsky_game.dart';
import 'package:marsky_shooter/game/state/game_phase.dart';

import '../helpers/test_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Geri tusu (handleBackRequest)', () {
    testWithGame<MarskyGame>('oynanista duraklatir, uygulamadan cikilmaz', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();

      final bool allowExit = game.handleBackRequest();

      expect(allowExit, isFalse, reason: 'oyun ortasinda uygulama kapanmamali');
      expect(game.phase.value, GamePhase.paused);
      expect(game.paused, isTrue);
    });

    testWithGame<MarskyGame>('duraklatmada ana menuye doner, uygulamadan cikilmaz', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();
      game.togglePause();
      expect(game.phase.value, GamePhase.paused);

      final bool allowExit = game.handleBackRequest();

      expect(allowExit, isFalse);
      expect(game.phase.value, GamePhase.menu);
      expect(game.paused, isFalse, reason: 'menude motor calismali');
    });

    testWithGame<MarskyGame>('oyun bitti ekraninda ana menuye doner', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();
      game.handlePlayerHit();
      expect(game.phase.value, GamePhase.gameOver);

      final bool allowExit = game.handleBackRequest();

      expect(allowExit, isFalse);
      expect(game.phase.value, GamePhase.menu);
    });

    testWithGame<MarskyGame>('ana menude cikisa izin verir', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      expect(game.phase.value, GamePhase.menu);

      final bool allowExit = game.handleBackRequest();

      expect(allowExit, isTrue, reason: 'menude geri tusu uygulamayi kapatmali');
      expect(game.phase.value, GamePhase.menu);
    });

    testWithGame<MarskyGame>('kademeli geri: oynanis -> duraklat -> menu -> cikis', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();
      game.startGame();

      // Oyuncunun sikisip kalmadigini kanitlar: art arda geri basarak cikisa
      // ulasilabiliyor.
      expect(game.handleBackRequest(), isFalse);
      expect(game.phase.value, GamePhase.paused);

      expect(game.handleBackRequest(), isFalse);
      expect(game.phase.value, GamePhase.menu);

      expect(game.handleBackRequest(), isTrue);
    });
  });
}
