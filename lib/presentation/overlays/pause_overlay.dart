import 'package:flutter/material.dart';

import '../../game/marsky_game.dart';
import 'widgets/overlay_panel.dart';
import 'widgets/sound_toggle_button.dart';

/// Duraklatma menusu.
/// (case PDF §2.B: "Duraklat (Pause): Oyunun tamamen durduğu ve devam
/// edilebildiği menü")
///
/// "Tamamen durdugu" ifadesi onemli: `pauseEngine()` cagrildigi icin `update`
/// dongusu hic calismaz, `dt` akmaz. Yalnizca cizim durdurulsa dusmanlar arka
/// planda hareket etmeye devam eder ve devam edildiginde oyuncu haksiz yere
/// olurdu.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({required this.game, super.key});

  final MarskyGame game;

  @override
  Widget build(BuildContext context) {
    return OverlayPanel(
      title: 'DURAKLATILDI',
      children: <Widget>[
        ValueListenableBuilder<int>(
          valueListenable: game.score.points,
          builder: (BuildContext context, int points, Widget? _) {
            return StatRow(label: 'SKOR', value: '$points');
          },
        ),
        const SizedBox(height: 20),
        MenuButton(label: 'DEVAM ET', onPressed: game.togglePause),
        const SizedBox(height: 10),
        MenuButton(
          label: 'ANA MENÜ',
          isPrimary: false,
          onPressed: game.goToMenu,
        ),
        const SizedBox(height: 4),
        const SoundToggleButton(),
      ],
    );
  }
}
