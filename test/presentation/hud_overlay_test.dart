import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/core/config/game_config.dart';
import 'package:marsky_shooter/game/marsky_game.dart';
import 'package:marsky_shooter/game/state/game_phase.dart';
import 'package:marsky_shooter/presentation/overlays/hud_overlay.dart';

import '../helpers/test_game.dart';

void main() {
  Future<MarskyGame> pumpHud(WidgetTester tester) async {
    final MarskyGame game = createSilentGame();
    await tester.pumpWidget(MaterialApp(home: HudOverlay(game: game)));
    return game;
  }

  group('HUD overlay', () {
    testWidgets('baslangicta sifir skor gosterir', (WidgetTester tester) async {
      await pumpHud(tester);

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('skor degistiginde metin guncellenir', (
      WidgetTester tester,
    ) async {
      final MarskyGame game = await pumpHud(tester);

      game.score.addEnemyKill();
      await tester.pump();

      expect(find.text('${GameConfig.scorePerEnemyKilled}'), findsOneWidget);

      game.score.addPickupCollected();
      await tester.pump();

      expect(
        find.text(
          '${GameConfig.scorePerEnemyKilled + GameConfig.scorePerPickupCollected}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('duraklat butonu oyunu duraklatir', (
      WidgetTester tester,
    ) async {
      final MarskyGame game = await pumpHud(tester);
      game.startGame();
      expect(game.phase.value, GamePhase.playing);

      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump();

      expect(game.phase.value, GamePhase.paused);
    });
  });
}
