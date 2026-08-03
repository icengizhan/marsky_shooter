import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/game/audio/game_audio.dart';
import 'package:marsky_shooter/game/components/player/player_component.dart';
import 'package:marsky_shooter/game/input/drag_input_component.dart';
import 'package:marsky_shooter/game/managers/enemy_spawner.dart';
import 'package:marsky_shooter/game/marsky_game.dart';

/// Testlerde ses platform kanali yoktur; sessiz uygulama enjekte edilir.
MarskyGame createSilentGame() => MarskyGame(audio: SilentGameAudio());

void main() {
  // Varlik yuklemesi (rootBundle) Flutter binding'i gerektirir; `testWithGame`
  // bunu kendisi kurmaz. Bu satir olmadan `images.loadAll` "Binding has not yet
  // been initialized" hatasi verir.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MarskyGame onLoad', () {
    testWithGame<MarskyGame>('oyuncu, spawner, girdi ve arka plan dunyaya eklenir', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();

      expect(game.playerOrNull, isNotNull);
      expect(game.world.children.whereType<PlayerComponent>().length, 1);
      expect(game.world.children.whereType<EnemySpawner>().length, 1);
      expect(game.world.children.whereType<DragInputComponent>().length, 1);
      expect(game.world.children.whereType<ParallaxComponent>().length, 1);
    });

    testWithGame<MarskyGame>('varliklar onbellege alinmis olur', createSilentGame, (
      MarskyGame game,
    ) async {
      await game.ready();

      // Preload calistiysa sprite'lar onbellekte olmali.
      expect(game.images.containsKey('player.png'), isTrue);
      expect(game.images.containsKey('enemy.png'), isTrue);
      expect(game.images.containsKey('bullet.png'), isTrue);
    });
  });
}
