import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/data/repositories/score_repository_impl.dart';
import 'package:marsky_shooter/game/marsky_game.dart';
import 'package:marsky_shooter/game/state/game_phase.dart';
import 'package:marsky_shooter/presentation/overlays/main_menu_overlay.dart';
import 'package:marsky_shooter/presentation/providers/app_providers.dart';

import '../helpers/in_memory_key_value_store.dart';
import '../helpers/test_game.dart';

void main() {
  /// Overlay'i sahte depoyla birlikte agaca yerlestirir.
  ///
  /// `ProviderScope(overrides:)` Riverpod'un test icin sundugu mekanizmadir:
  /// yalnizca EN ALTTAKI bagimlilik (disk) degistirilir, provider'lar ve
  /// repository gercek kodla calisir.
  Future<MarskyGame> pumpMenu(
    WidgetTester tester,
    InMemoryKeyValueStore store,
  ) async {
    final MarskyGame game = createSilentGame();
    await tester.pumpWidget(
      ProviderScope(
        // Tip belirtilmiyor: Riverpod 3'te `Override` sinifi disa aktarilmiyor,
        // tip cikarimi kullanilir.
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
        child: MaterialApp(home: MainMenuOverlay(game: game)),
      ),
    );
    await tester.pumpAndSettle();
    return game;
  }

  group('Ana menu overlay', () {
    testWidgets('kayitli en yuksek skoru gosterir', (
      WidgetTester tester,
    ) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      store.values[ScoreRepositoryImpl.highScoreKey] = 1234;

      await pumpMenu(tester, store);

      expect(find.text('EN YÜKSEK SKOR'), findsOneWidget);
      expect(find.text('1234'), findsOneWidget);
    });

    testWidgets('kayit yoksa sifir gosterir', (WidgetTester tester) async {
      await pumpMenu(tester, InMemoryKeyValueStore());

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('kural ozeti ve puan degerleri gorunur', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester, InMemoryKeyValueStore());

      expect(find.text('NASIL OYNANIR'), findsOneWidget);
      expect(find.text('Elmas topla'), findsOneWidget);
      expect(find.text('Düşmana çarparsan oyun biter'), findsOneWidget);
    });

    testWidgets('BASLA butonu oyunu baslatir', (WidgetTester tester) async {
      final MarskyGame game = await pumpMenu(tester, InMemoryKeyValueStore());
      expect(game.phase.value, GamePhase.menu);

      await tester.tap(find.text('BAŞLA'));
      await tester.pump();

      expect(game.phase.value, GamePhase.playing);
    });

    testWidgets('skor gecmisi bos ise "SON OYUNLAR" gosterilmez', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester, InMemoryKeyValueStore());

      expect(find.text('SON OYUNLAR'), findsNothing);
    });

    testWidgets('skor gecmisi varsa listelenir', (WidgetTester tester) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      store.values[ScoreRepositoryImpl.historyKey] =
          '[{"points":770,"achievedAt":"2026-08-04T09:15:00.000Z"}]';

      await pumpMenu(tester, store);

      expect(find.text('SON OYUNLAR'), findsOneWidget);
      expect(find.text('770'), findsOneWidget);
    });
  });
}
