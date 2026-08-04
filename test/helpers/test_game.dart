import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:marsky_shooter/core/config/game_config.dart';
import 'package:marsky_shooter/game/audio/game_audio.dart';
import 'package:marsky_shooter/game/marsky_game.dart';
import 'package:marsky_shooter/game/state/game_overlays.dart';

/// Testler icin oyun ornegi kurar.
///
/// Iki sey uretim ortamindan farklidir ve ikisi de bilincli:
///
/// 1. **Sessiz ses.** Gercek `FlameGameAudio`, arka planda `path_provider`
///    platform kanalini kullanir; unit test ortaminda bu kanal yoktur ve
///    `MissingPluginException` atilir. [SilentGameAudio] enjekte edilir.
///
/// 2. **Overlay kayitlari.** Uretimde overlay widget'larini `GameWidget`in
///    `overlayBuilderMap`i kaydeder. Unit testte `GameWidget` yoktur, bu yuzden
///    oyun `overlays.add(...)` cagirdiginda Flame "Trying to add an unknown
///    overlay" assert'i atar. Burada ayni kimlikler bos builder'larla
///    kaydedilir -- assert guvenlik agi devrede kalir, yalnizca cizilecek
///    widget bos olur.
/// 60 FPS'te bir karenin suresi.
const double frameSeconds = 1 / 60;

/// Oyunu [seconds] saniye boyunca KARE KARE ilerletir.
///
/// Tek buyuk bir `update(seconds)` cagrisi gercekci olmaz: `dt` ile olcekleme
/// hatalari, sayac biriktirme ve carpisma taramasi ancak coklu kucuk karelerde
/// dogru sinanir.
void advance(MarskyGame game, double seconds) {
  final int frames = (seconds / frameSeconds).round();
  for (int i = 0; i < frames; i++) {
    game.update(frameSeconds);
  }
}

/// [advance] gibi kare kare ilerletir, AMA her karenin ardindan olay dongusunun
/// donmesine izin verir.
///
/// NEDEN GEREKLI: Flame'in `ComponentPool`u nesneyi `component.removed` Future'i
/// tamamlaninca havuza geri verir. Tamamen senkron bir dongude Future'lar hic
/// tamamlanmaz; havuz bos kalir ve "geri donusum calismiyor" gibi YANLIS bir
/// olcum elde edilir. Gercek oyunda kareler arasinda olay dongusu dondugu icin
/// bu sorun yoktur.
///
/// Yalnizca asenkron tamamlanmaya dayanan davranislari (havuz gibi) olcen
/// testlerde kullanilir; digerleri icin [advance] daha hizlidir.
Future<void> advanceAsync(MarskyGame game, double seconds) async {
  final int frames = (seconds / frameSeconds).round();
  for (int i = 0; i < frames; i++) {
    game.update(frameSeconds);
    await Future<void>.delayed(Duration.zero);
  }
}

/// Oyuncuyu oldurur ve olum animasyonu penceresinin gecmesini bekler.
///
/// `handlePlayerHit()` ARTIK ANINDA "oyun bitti" durumuna gecmiyor: patlama ve
/// ekran sarsintisi gorunebilsin diye [GameConfig.deathAnimationDuration]
/// kadar bir pencere var (bkz. `MarskyGame.handlePlayerHit`). Testler bu
/// pencereyi beklemezse `phase` hala `playing` gorunur.
void killPlayerAndSettle(MarskyGame game) {
  game.handlePlayerHit();
  // Pencerenin bittiginden emin olmak icin kucuk bir pay eklenir.
  advance(game, GameConfig.deathAnimationDuration + 0.1);
}

/// Testlerin tekrarlanabilir olmasi icin SABIT tohum.
///
/// Tohumsuz `Random()` ile testler sansa bagli olarak kirilir. Bu gercekten
/// yasandi: "duraklatilmisken skor artmaz" testi, duraklatma penceresinde
/// tesadufi bir mermi isabeti olustugunda kiriliyordu.
const int testRandomSeed = 20260804;

MarskyGame createSilentGame() {
  final MarskyGame game = MarskyGame(
    audio: SilentGameAudio(),
    random: Random(testRandomSeed),
  );

  for (final String overlayId in <String>[
    GameOverlays.mainMenu,
    GameOverlays.hud,
    GameOverlays.pause,
    GameOverlays.gameOver,
  ]) {
    game.overlays.addEntry(
      overlayId,
      (BuildContext context, Game game) => const SizedBox.shrink(),
    );
  }

  return game;
}
