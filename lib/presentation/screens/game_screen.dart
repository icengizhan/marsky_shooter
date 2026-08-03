import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/game_config.dart';
import '../../game/marsky_game.dart';
import '../../game/state/game_overlays.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/hud_overlay.dart';
import '../overlays/main_menu_overlay.dart';
import '../overlays/pause_overlay.dart';
import '../providers/settings_providers.dart';

/// Oyunu barindiran ekran.
///
/// NEDEN `StatefulWidget` VE NEDEN `GameWidget.controlled` DEGIL:
/// Ses ayarini oyuna uygulamak icin oyun ORNEGINE bir referans gerekiyor.
/// `GameWidget.controlled` ornegi kendi icinde yaratir ve disariya vermez.
/// Ornek burada `initState` icinde BIR KEZ yaratilir; `build` icinde
/// yaratilsaydi her yeniden kurulumda oyun basa saracak ve bellek sizacakti.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final MarskyGame _game;

  @override
  void initState() {
    super.initState();
    _game = MarskyGame();

    // Riverpod'daki ses ayarini oyunun ses kapisina aktarir.
    // BU TEK YER sayesinde oyun motoru Riverpod'u hic bilmez -- baglanti
    // sunum katmaninda kalir.
    //
    // `listenManual` kullanilir, `build` icindeki `ref.listen` degil:
    // Riverpod 3'te `ref.listen`in `fireImmediately` secenegi YOKTUR.
    // `listenManual` aboneligi widget yasam dongusune baglar ve ayar diskten
    // okundugu anda ilk degeri de uygular -- kullanicinin dokunmasini beklemez.
    ref.listenManual<AsyncValue<bool>>(
      soundEnabledProvider,
      (AsyncValue<bool>? previous, AsyncValue<bool> next) {
        final bool? isEnabled = next.value;
        if (isEnabled != null) {
          _game.audio.setMuted(!isEnabled);
        }
      },
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConfig.spaceColor,
      body: GameWidget<MarskyGame>(
        game: _game,
        // Overlay kimlikleri ile widget'lar burada eslesir. Oyun motoru
        // yalnizca kimlikleri bilir, widget'lari bilmez.
        overlayBuilderMap: <String, OverlayWidgetBuilder<MarskyGame>>{
          GameOverlays.mainMenu: (BuildContext context, MarskyGame game) =>
              MainMenuOverlay(game: game),
          GameOverlays.hud: (BuildContext context, MarskyGame game) =>
              HudOverlay(game: game),
          GameOverlays.pause: (BuildContext context, MarskyGame game) =>
              PauseOverlay(game: game),
          GameOverlays.gameOver: (BuildContext context, MarskyGame game) =>
              GameOverOverlay(game: game),
        },
      ),
    );
  }
}
