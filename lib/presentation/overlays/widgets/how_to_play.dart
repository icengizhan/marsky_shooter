import 'package:flutter/material.dart';

import '../../../core/config/game_config.dart';

/// Ana menudeki kisa kural ozeti.
///
/// NEDEN AYRI BIR TUTORIAL EKRANI DEGIL:
/// Ayri bir ogretici ekran, durum makinesine besinci bir durum eklemek demektir
/// (gecis yonetimi, geri donus, test). Case "karmaşık senaryolara gerek yoktur"
/// diyor. Bunun yerine kurallar ana menude, her acilista gorunur sekilde
/// ozetlenir -- oyuncu ekstra bir adim atmadan ogrenir.
///
/// Metin yerine OYUNUN GERCEK SPRITE'LARI kullanilir: oyuncu menude gordugu
/// gorseli oyun icinde birebir tanir, okumaya gerek kalmaz.
class HowToPlay extends StatelessWidget {
  const HowToPlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Divider(color: Color(0x227DEAFF), height: 20),
        const Text(
          'NASIL OYNANIR',
          style: TextStyle(
            color: Color(0x66FFFFFF),
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        // Sira bilincli: once KONTROL (oyuncunun ilk ihtiyaci), sonra PUAN
        // kaynaklari, en sona TEHLIKE -- son okunan en akilda kalandir.
        const _RuleRow(
          icon: Icons.touch_app_rounded,
          text: 'Ekranı sürükle: gemi hareket eder',
        ),
        const _RuleRow(
          image: 'assets/images/bullet.png',
          text: 'Ateş otomatik · düşmanı vur',
          value: '+${GameConfig.scorePerEnemyKilled}',
        ),
        // Elmas satiri PUANDAN once GUCU soyluyor: oyuncunun bilmesi gereken
        // asil sey silahin yukselmesi, puan ikincil. Yukari cikip elmas almak
        // oyundaki tek gercek risk/odul karari ve bu satir onu ogretiyor.
        const _RuleRow(
          image: 'assets/images/pickup.png',
          text: 'Elmas topla: silahın güçlenir',
          value: '+${GameConfig.scorePerPickupCollected}',
        ),
        const _RuleRow(
          icon: Icons.schedule_rounded,
          text: 'Her saniye hayatta kal',
          value: '+${GameConfig.scorePerSecond}',
        ),
        const _RuleRow(
          icon: Icons.favorite_rounded,
          text:
              '${GameConfig.playerMaxLives} canın var · vurulunca silah düşer',
          accent: Color(0xFFFF5C8A),
        ),
        const _RuleRow(
          image: 'assets/images/enemy.png',
          text: 'Canın biterse oyun biter',
          accent: Color(0xFFFF76C4),
        ),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.text,
    this.image,
    this.icon,
    this.value,
    this.accent,
  });

  final String text;
  final String? image;
  final IconData? icon;
  final String? value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 26,
            height: 26,
            child: Center(
              child: image != null
                  ? Image.asset(image!, width: 24, height: 24)
                  : Icon(icon, size: 20, color: const Color(0xFFB8E9F5)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: const TextStyle(
                color: Color(0xFF7DEAFF),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (accent != null)
            Icon(Icons.dangerous_rounded, size: 16, color: accent),
        ],
      ),
    );
  }
}
