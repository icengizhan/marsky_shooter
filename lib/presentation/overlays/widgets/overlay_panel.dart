import 'package:flutter/material.dart';

/// Menu / duraklat / oyun bitti ekranlarinin ortak kabugu.
///
/// Uc overlay ayni gorsel dili paylasir. Bu kabuk cikarilmasa her overlay kendi
/// scrim, panel, kose yariciapi ve baslik stilini tekrar yazardi -- degisiklik
/// gerektiginde uc dosyayi duzenlemek gerekirdi.
class OverlayPanel extends StatelessWidget {
  const OverlayPanel({
    required this.title,
    required this.children,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      // Oyun tuvalinin uzerini karartir: metin okunur olur ve oynanisin
      // durdugu gorsel olarak belli olur.
      color: const Color(0xCC03040C),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xF20B1020),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x337DEAFF), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF7DEAFF),
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      height: 1.1,
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Panel icindeki birincil eylem butonu.
class MenuButton extends StatelessWidget {
  const MenuButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: isPrimary
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF17C8E6),
                foregroundColor: const Color(0xFF041018),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(label, style: _labelStyle),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB8E9F5),
                side: const BorderSide(color: Color(0x557DEAFF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(label, style: _labelStyle),
            ),
    );
  }

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
  );
}

/// Etiket + deger satiri (ornek: "EN YUKSEK SKOR   1240").
class StatRow extends StatelessWidget {
  const StatRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          // Expanded ZORUNLU: etiket sabit genislikte olsaydi uzun bir deger
          // (ornegin 6 haneli bir skor) satiri tasirdi ve Flutter sari-siyah
          // tasma seridi cizerdi. Widget testi bu hatayi yakaladi
          // (test/presentation/game_over_overlay_test.dart).
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0x99FFFFFF),
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
