import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
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

MarskyGame createSilentGame() {
  final MarskyGame game = MarskyGame(audio: SilentGameAudio());

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
