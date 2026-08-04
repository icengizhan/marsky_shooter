import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/game_config.dart';
import '../../game/marsky_game.dart';
import '../../game/state/game_overlays.dart';
import '../../game/state/game_phase.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/hud_overlay.dart';
import '../overlays/main_menu_overlay.dart';
import '../overlays/pause_overlay.dart';
import '../providers/settings_providers.dart';
import 'game_boot_views.dart';

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

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  late final MarskyGame _game;

  @override
  void initState() {
    super.initState();
    _game = MarskyGame();

    // Uygulama yasam dongusunu dinler: arka plana alinirsa oyun duraklatilir.
    WidgetsBinding.instance.addObserver(this);

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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Uygulama arka plana alindiginda / telefon kilitlendiginde oyunu duraklatir.
  ///
  /// Bu olmadan: oyuncuya arama gelir, oyun arka planda calismaya devam eder ve
  /// geri dondugunde olmus olur. Mobil bir oyunda bu kabul edilemez.
  /// WidgetsBindingObserver.didChangeAppLifecycleState
  /// (Flutter SDK — https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver/didChangeAppLifecycleState.html)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) {
      _game.pauseIfPlaying();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConfig.spaceColor,
      // Geri tusunu ele almak icin oyunun durumunu bilmek gerekiyor: sistem
      // cikisina YALNIZCA ana menude izin verilir.
      body: ValueListenableBuilder<GamePhase>(
        valueListenable: _game.phase,
        // `child` parametresi onemli: GameWidget burada BIR KEZ kurulur ve
        // durum her degistiginde yeniden kurulmaz. `builder` icine yazilsaydi
        // her menu/duraklat gecisinde oyun widget'i bastan insa edilirdi.
        child: GameWidget<MarskyGame>(
          game: _game,
          // Varliklar yuklenirken marka uyumlu bir ekran; verilmezse bos/siyah
          // bir bosluk gorunur.
          loadingBuilder: (BuildContext context) => const GameLoadingView(),
          // Yukleme hatasinda Flutter'in kirmizi hata ekrani yerine anlasilir
          // bir panel; verilmezse hata yukari firlatilir.
          errorBuilder: (BuildContext context, Object error) =>
              GameErrorView(error: error),
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
        builder: (BuildContext context, GamePhase phase, Widget? child) {
          return PopScope(
            // Yalnizca ana menude geri tusu uygulamayi kapatabilir.
            canPop: phase == GamePhase.menu,
            onPopInvokedWithResult: (bool didPop, Object? result) {
              // didPop true ise sistem cikisi zaten gerceklesti (menudeydik).
              if (didPop) {
                return;
              }
              // Karari oyun verir: oynanis -> duraklat -> menu.
              _game.handleBackRequest();
            },
            child: child!,
          );
        },
      ),
    );
  }
}
