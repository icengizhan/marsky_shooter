import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/core/config/game_config.dart';
import 'package:marsky_shooter/game/marsky_game.dart';
import 'package:marsky_shooter/game/state/game_phase.dart';
import 'package:marsky_shooter/presentation/overlays/pause_overlay.dart';
import 'package:marsky_shooter/presentation/providers/app_providers.dart';

import '../helpers/in_memory_key_value_store.dart';
import '../helpers/test_game.dart';

/// DURAKLATMA EKRANI TESTLERI.
///
/// NEDEN SONRADAN EKLENDI: kapsam olcumu bu dosyanin %0'da oldugunu gosterdi.
/// Diger uc overlay'in widget testi vardi, duraklatmanin yoktu -- test sayisina
/// bakip "yeterli" demenin neden yanlis oldugunun somut ornegi.
void main() {
  /// Oyunu duraklatilmis duruma getirip overlay'i cizer.
  Future<MarskyGame> pumpPaused(
    WidgetTester tester, {
    int enemyKills = 0,
  }) async {
    final MarskyGame game = createSilentGame();
    for (int i = 0; i < enemyKills; i++) {
      game.score.addEnemyKill();
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore()),
        ],
        child: MaterialApp(home: PauseOverlay(game: game)),
      ),
    );
    await tester.pumpAndSettle();
    return game;
  }

  group('Duraklatma overlay', () {
    testWidgets('baslik ve anlik skoru gosterir', (WidgetTester tester) async {
      await pumpPaused(tester, enemyKills: 4);

      expect(find.text('DURAKLATILDI'), findsOneWidget);
      expect(find.text('SKOR'), findsOneWidget);
      expect(
        find.text('${4 * GameConfig.scorePerEnemyKilled}'),
        findsOneWidget,
        reason: 'duraklatma ekrani o ana kadarki skoru gostermeli',
      );
    });

    testWidgets('skor degisince gosterim guncellenir', (
      WidgetTester tester,
    ) async {
      // `ValueListenableBuilder` gercekten bagli mi? Duraklatmada skor artmaz
      // ama bu widget'in canli degeri dinledigini dogrulamak, ileride HUD ile
      // ayni hatayi paylasmasini onler.
      final MarskyGame game = await pumpPaused(tester);
      expect(find.text('0'), findsOneWidget);

      game.score.addPickupCollected();
      await tester.pump();

      expect(
        find.text('${GameConfig.scorePerPickupCollected}'),
        findsOneWidget,
      );
    });

    testWidgets('DEVAM ET oyuna geri doner', (WidgetTester tester) async {
      final MarskyGame game = await pumpPaused(tester);
      // Duraklatma durumuna gecmek icin once oynanisa girip duraklatmak gerekir.
      game.startGame();
      game.togglePause();
      expect(game.phase.value, GamePhase.paused);

      await tester.tap(find.text('DEVAM ET'));
      await tester.pump();

      expect(game.phase.value, GamePhase.playing);
    });

    testWidgets('ANA MENU menuye doner ve skoru sifirlar', (
      WidgetTester tester,
    ) async {
      final MarskyGame game = await pumpPaused(tester, enemyKills: 3);
      game.startGame();
      game.togglePause();

      await tester.tap(find.text('ANA MENÜ'));
      await tester.pump();

      expect(game.phase.value, GamePhase.menu);
      expect(
        game.score.points.value,
        0,
        reason: 'menuye donunce skor sifirlanmali',
      );
    });

    testWidgets('ses dugmesi bulunur', (WidgetTester tester) async {
      await pumpPaused(tester);

      // Duraklatma, oyuncunun sesi kapatmak icin en dogal ugradigi yer;
      // dugmenin burada bulunmasi bilincli.
      expect(find.byType(IconButton), findsOneWidget);
    });
  });
}
