import 'package:flutter/material.dart';

import '../../game/marsky_game.dart';

/// Oyun ici ust bilgi cubugu: anlik skor ve duraklat dugmesi.
/// (case PDF §2.A: "ekranda anlık güncellenen bir skor sistemi")
///
/// KRITIK PERFORMANS NOKTASI: skor `ValueListenableBuilder` ile dinlenir.
/// Boylece skor degistiginde YALNIZCA metin widget'i yeniden kurulur.
/// `setState` kullanilsa ya da skor Riverpod uzerinden akitilsa, saniyede
/// onlarca kez tum HUD agaci yeniden kurulur ve kare hizi duserdi.
class HudOverlay extends StatelessWidget {
  const HudOverlay({required this.game, super.key});

  final MarskyGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ValueListenableBuilder<int>(
              valueListenable: game.score.points,
              builder: (BuildContext context, int points, Widget? _) {
                return Text(
                  '$points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    // tabularFigures: rakamlar esit genislikte olur, skor
                    // artarken metin saga sola oynamaz.
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                    shadows: <Shadow>[
                      Shadow(color: Color(0xFF0A1830), blurRadius: 6),
                    ],
                  ),
                );
              },
            ),
            const Spacer(),
            IconButton(
              onPressed: game.togglePause,
              tooltip: 'Duraklat',
              icon: const Icon(
                Icons.pause_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
