import 'package:flutter/material.dart';

import '../presentation/screens/game_screen.dart';

/// Uygulama kabugu.
///
/// Oyunun kendisi bir Flutter widget agaci DEGILDIR: oynanisin tamami Flame
/// component'lerinde calisir (case PDF §3: standart Flutter widget'lari ile
/// yapilan oyunlar reddedilir). Flutter widget'lari yalnizca menu / HUD /
/// pause / game over overlay'lerinde kullanilir -- bu, Flame'in kendi onerdigi
/// yaklasimdir (`game.overlays`).
class MarskyApp extends StatelessWidget {
  const MarskyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MARSKY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const GameScreen(),
    );
  }
}
