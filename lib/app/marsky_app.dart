import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/marsky_game.dart';

/// Uygulama kabugu.
///
/// Oyunun kendisi bir Flutter widget agaci DEGILDIR: burada sadece Flame'in
/// tuvalini barindiran [GameWidget] var. Tum oynanis Flame component'lerinde
/// calisir (case PDF §3: standart Flutter widget'lari ile yapilan oyunlar
/// reddedilir). Flutter widget'lari yalnizca Faz 6'da eklenecek menu / HUD /
/// pause / game over overlay'lerinde kullanilacak.
class MarskyApp extends StatelessWidget {
  const MarskyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MARSKY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      // GameWidget.controlled: oyun ornegini widget'in kendisi yonetir.
      // Duz `GameWidget(game: MarskyGame())` yazilsaydi her rebuild'de YENI bir
      // oyun ornegi olusur, oyun basa sarardi ve bellek sizardi.
      // (Flame — https://docs.flame-engine.org/latest/flame/game_widget.html)
      home: const Scaffold(
        body: GameWidget<MarskyGame>.controlled(gameFactory: MarskyGame.new),
      ),
    );
  }
}
