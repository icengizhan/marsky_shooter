import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/marsky_app.dart';
import 'core/diagnostics/frame_report.dart';

/// Giris noktasi. Bilincli olarak minimal tutuldu: burada is mantigi yoktur.
///
/// runApp (Flutter SDK — https://api.flutter.dev/flutter/widgets/runApp.html)
Future<void> main() async {
  // Platform kanallarini (SystemChrome, shared_preferences) kullanmadan once
  // binding'in hazir olmasi gerekir.
  WidgetsFlutterBinding.ensureInitialized();

  // Oyun 480x800 dikey tasarima gore kurgulanmistir; yatay cevirmede oynanis
  // alani bozulacagi icin dikey moda kilitlenir.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Kare suresi olcumu: YALNIZCA profil modunda calisir, release'de kodun
  // tamami elenir. "Performansli" iddiasini olculebilir kilar.
  FrameReport.startIfProfileMode();

  // ProviderScope: Riverpod'un tum provider'lari bu kapsamda yasar.
  // Oyun disi state (yuksek skor, ses ayari, skor gecmisi) buradan akar.
  runApp(const ProviderScope(child: MarskyApp()));
}
