import 'package:flutter/material.dart';

import '../../core/config/game_config.dart';
import '../../game/marsky_game.dart';

/// Oyun ici ust bilgi cubugu: anlik skor, kalan can, silah seviyesi ve
/// duraklat dugmesi. Ayrica seviye atlandiginda ekranin ortasinda kisa bir
/// "SEVIYE N" yazisi gosterir.
/// (case PDF §2.A: "ekranda anlık güncellenen bir skor sistemi")
///
/// KRITIK PERFORMANS NOKTASI: her canli deger AYRI bir
/// `ValueListenableBuilder` ile dinlenir. Boylece skor degistiginde yalnizca
/// skor metni yeniden kurulur; can ve silah gostergesi kendi degerleri
/// degismedikce hic dokunulmaz. Tek bir builder'a sarilsalar ya da state
/// Riverpod'dan aksa, saniyede onlarca kez tum HUD agaci yeniden kurulurdu.
class HudOverlay extends StatelessWidget {
  const HudOverlay({required this.game, super.key});

  final MarskyGame game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _ScoreText(game: game),
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
                Row(
                  children: <Widget>[
                    _LivesRow(game: game),
                    const Spacer(),
                    _WeaponLevelChip(game: game),
                  ],
                ),
              ],
            ),
          ),
        ),
        _LevelBanner(game: game),
      ],
    );
  }
}

class _ScoreText extends StatelessWidget {
  const _ScoreText({required this.game});

  final MarskyGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.score.points,
      builder: (BuildContext context, int points, Widget? _) {
        return Text(
          '$points',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            // tabularFigures: rakamlar esit genislikte olur, skor artarken
            // metin saga sola oynamaz.
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            shadows: <Shadow>[Shadow(color: Color(0xFF0A1830), blurRadius: 6)],
          ),
        );
      },
    );
  }
}

/// Kalan canlar. Harcanan canlar SILINMEZ, soluk gosterilir: oyuncu kac hakki
/// oldugunu degil kac hakkini KAYBETTIGINI de gorur.
class _LivesRow extends StatelessWidget {
  const _LivesRow({required this.game});

  final MarskyGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.run.lives,
      builder: (BuildContext context, int lives, Widget? _) {
        return Row(
          children: List<Widget>.generate(GameConfig.playerMaxLives, (int i) {
            final bool isRemaining = i < lives;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                isRemaining ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: isRemaining
                    ? const Color(0xFFFF5C8A)
                    : const Color(0x44FFFFFF),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Silah seviyesi gostergesi. Tavana ulasinca "MAX" yazar; sayinin durmasi
/// oyuncuya "daha fazlasi yok" bilgisini vermez, kelime verir.
class _WeaponLevelChip extends StatelessWidget {
  const _WeaponLevelChip({required this.game});

  final MarskyGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.run.weaponLevel,
      builder: (BuildContext context, int level, Widget? _) {
        final bool isMax = level >= GameConfig.maxWeaponLevel;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0x33000000),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isMax ? const Color(0xFFFFD54A) : const Color(0x557DEAFF),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.bolt_rounded,
                size: 14,
                color: isMax
                    ? const Color(0xFFFFD54A)
                    : const Color(0xFF7DEAFF),
              ),
              const SizedBox(width: 3),
              Text(
                isMax ? 'MAX' : 'Lv $level',
                style: TextStyle(
                  color: isMax
                      ? const Color(0xFFFFD54A)
                      : const Color(0xFF7DEAFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Seviye atlandiginda ekranin ortasinda kisa sure gorunen yazi.
///
/// `IgnorePointer` sart: banner ekranin ortasinda duruyor ve oyun sirasinda
/// surukleme girdisini yakalarsa gemi hareket etmez.
class _LevelBanner extends StatelessWidget {
  const _LevelBanner({required this.game});

  final MarskyGame game;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<int>(
        valueListenable: game.levelBanner,
        builder: (BuildContext context, int level, Widget? _) {
          // 0 = gosterilecek seviye yok.
          if (level <= 0) {
            return const SizedBox.shrink();
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'SEVİYE $level',
                  style: const TextStyle(
                    color: Color(0xFF7DEAFF),
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    shadows: <Shadow>[
                      Shadow(color: Color(0xFF001018), blurRadius: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'DÜŞMANLAR HIZLANIYOR',
                  style: TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
