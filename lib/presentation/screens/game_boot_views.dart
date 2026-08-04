import 'package:flutter/material.dart';

import '../../core/config/game_config.dart';

/// Varliklar onbellege alinirken gosterilen ekran.
///
/// NEDEN GEREKLI: `GameWidget`e `loadingBuilder` verilmezse yukleme suresince
/// bos/siyah bir ekran gorunur. Sure kisa olsa da marka kimligi olmayan bir
/// bosluk "uygulama acilmadi" hissi verir. Buradaki ekran acilis renginin
/// aynisini kullanir, yani acilistan oyuna gecis kesintisizdir.
class GameLoadingView extends StatelessWidget {
  const GameLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: GameConfig.spaceColor,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'MARSKY',
              style: TextStyle(
                color: Color(0xFF7DEAFF),
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
              ),
            ),
            SizedBox(height: 22),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF17C8E6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Varlik yuklemesi basarisiz olursa gosterilen ekran.
///
/// NEDEN GEREKLI: `errorBuilder` verilmezse Flame hatayi yukari firlatir ve
/// kullanici Flutter'in kirmizi hata ekranini gorur. Bir oyunda bu kabul
/// edilemez; hem cirkin hem de kullaniciya ne yapacagini soylemez.
class GameErrorView extends StatelessWidget {
  const GameErrorView({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: GameConfig.spaceColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF76C4),
                size: 44,
              ),
              const SizedBox(height: 14),
              const Text(
                'OYUN YÜKLENEMEDİ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF7DEAFF),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Görsel veya ses dosyaları açılamadı.\n'
                'Uygulamayı kapatıp tekrar açmayı dene.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              // Teknik ayrinti gelistirici icin durur ama one cikmaz.
              Text(
                '$error',
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0x55FFFFFF),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
