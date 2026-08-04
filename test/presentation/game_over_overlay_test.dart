import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/core/config/game_config.dart';
import 'package:marsky_shooter/data/repositories/score_repository_impl.dart';
import 'package:marsky_shooter/game/marsky_game.dart';
import 'package:marsky_shooter/game/state/game_phase.dart';
import 'package:marsky_shooter/presentation/overlays/game_over_overlay.dart';
import 'package:marsky_shooter/presentation/providers/app_providers.dart';

import '../helpers/in_memory_key_value_store.dart';
import '../helpers/test_game.dart';

void main() {
  /// Oyunu verilen sonucla "oyun bitti" durumuna getirip overlay'i cizer.
  Future<MarskyGame> pumpGameOver(
    WidgetTester tester,
    InMemoryKeyValueStore store, {
    int enemyKills = 0,
    int pickups = 0,
  }) async {
    final MarskyGame game = createSilentGame();
    for (int i = 0; i < enemyKills; i++) {
      game.score.addEnemyKill();
    }
    for (int i = 0; i < pickups; i++) {
      game.score.addPickupCollected();
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
        child: MaterialApp(home: GameOverOverlay(game: game)),
      ),
    );
    await tester.pumpAndSettle();
    return game;
  }

  group('Oyun bitti overlay', () {
    testWidgets('son skoru ve dokumu gosterir', (WidgetTester tester) async {
      await pumpGameOver(
        tester,
        InMemoryKeyValueStore(),
        enemyKills: 3,
        pickups: 2,
      );

      final int expectedTotal =
          3 * GameConfig.scorePerEnemyKilled +
          2 * GameConfig.scorePerPickupCollected;

      expect(find.text('OYUN BİTTİ'), findsOneWidget);
      expect(find.text('PUAN NEREDEN GELDİ'), findsOneWidget);
      expect(find.text('Vurulan düşman'), findsOneWidget);
      expect(find.text('Toplanan elmas'), findsOneWidget);
      // Toplam hem SKOR hem EN YUKSEK SKOR satirinda gorunur (rekor kirildi).
      expect(find.text('$expectedTotal'), findsWidgets);
    });

    testWidgets('skoru kalici depoya yazar', (WidgetTester tester) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();

      await pumpGameOver(tester, store, enemyKills: 5);

      final int expected = 5 * GameConfig.scorePerEnemyKilled;
      expect(
        store.values[ScoreRepositoryImpl.highScoreKey],
        expected,
        reason: 'yuksek skor diske yazilmali',
      );
      expect(
        store.values[ScoreRepositoryImpl.historyKey],
        isNotNull,
        reason: 'skor gecmisine kayit eklenmeli',
      );
    });

    testWidgets('rekor kirildiginda YENI REKOR gosterir', (
      WidgetTester tester,
    ) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      store.values[ScoreRepositoryImpl.highScoreKey] = 5;

      await pumpGameOver(tester, store, enemyKills: 4);

      expect(find.text('YENİ REKOR'), findsOneWidget);
    });

    testWidgets('rekor kirilmadiysa YENI REKOR gosterilmez', (
      WidgetTester tester,
    ) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      store.values[ScoreRepositoryImpl.highScoreKey] = 100000;

      await pumpGameOver(tester, store, enemyKills: 1);

      expect(find.text('YENİ REKOR'), findsNothing);
    });

    testWidgets('mevcut rekordan dusukse depodaki deger korunur', (
      WidgetTester tester,
    ) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      store.values[ScoreRepositoryImpl.highScoreKey] = 100000;

      await pumpGameOver(tester, store, enemyKills: 1);

      expect(
        store.values[ScoreRepositoryImpl.highScoreKey],
        100000,
        reason: 'daha dusuk skor rekoru EZMEMELI',
      );
    });

    testWidgets(
      'kayit ucustayken overlay kapanirsa skor gene de diske yazilir',
      (WidgetTester tester) async {
        // GERCEK HATA SENARYOSU: soguk acilista yuksek skor okumasi diskten
        // gelirken oyuncu "TEKRAR DENE"ye basarsa bu overlay agactan cikar.
        // Kayit fonksiyonu `await`ten SONRA `ref`e dokunuyorsa Riverpod
        // "widget dispose edildikten sonra ref kullanildi" diye firlatir;
        // hata `unawaited` icinde yutulur ve OYUNCUNUN REKORU KAYBOLUR.
        final InMemoryKeyValueStore store = InMemoryKeyValueStore(
          readDelay: const Duration(milliseconds: 40),
        );
        final MarskyGame game = createSilentGame();
        game.score.addEnemyKill();

        final ValueNotifier<bool> isOverlayVisible = ValueNotifier<bool>(true);
        addTearDown(isOverlayVisible.dispose);

        await tester.pumpWidget(
          ProviderScope(
            // ProviderScope AYNI KALIR, yalnizca cocuk degisir: gercek
            // uygulamada da kapsam GameScreen'in uzerindedir, overlay ile
            // birlikte yok olmaz.
            overrides: [keyValueStoreProvider.overrideWithValue(store)],
            child: MaterialApp(
              home: ValueListenableBuilder<bool>(
                valueListenable: isOverlayVisible,
                builder: (BuildContext _, bool isVisible, Widget? _) =>
                    isVisible ? GameOverOverlay(game: game) : const SizedBox(),
              ),
            ),
          ),
        );
        await tester.pump();

        // Okuma henuz bitmedi; oyuncu ekrani kapatiyor.
        isOverlayVisible.value = false;
        await tester.pump();

        // Gecikmeli okuma simdi tamamlanir.
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(
          store.values[ScoreRepositoryImpl.highScoreKey],
          GameConfig.scorePerEnemyKilled,
          reason: 'ekran kapansa bile skor kaydi tamamlanmali',
        );
      },
    );

    testWidgets('TEKRAR DENE yeni oyun baslatir', (WidgetTester tester) async {
      final MarskyGame game = await pumpGameOver(
        tester,
        InMemoryKeyValueStore(),
        enemyKills: 2,
      );

      await tester.tap(find.text('TEKRAR DENE'));
      await tester.pump();

      expect(game.phase.value, GamePhase.playing);
      expect(game.score.points.value, 0, reason: 'skor sifirlanmali');
    });

    testWidgets('ANA MENU menuye doner', (WidgetTester tester) async {
      final MarskyGame game = await pumpGameOver(
        tester,
        InMemoryKeyValueStore(),
        enemyKills: 2,
      );

      await tester.tap(find.text('ANA MENÜ'));
      await tester.pump();

      expect(game.phase.value, GamePhase.menu);
    });
  });
}
