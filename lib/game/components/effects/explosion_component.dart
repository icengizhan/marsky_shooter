import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../../../core/config/game_config.dart';

/// Buyuyerek solan patlama/parlama halkasi.
///
/// NEDEN GEREKLI: bu efekt olmadan vurulan dusman bir anda yok oluyordu ve
/// yalnizca ses duyuluyordu. Oyuncu isabetin gerceklestigini goremiyor, vurus
/// "tatmin etmiyor". Olum aninda da ekran birden donuyor, oyuncu neden oldugunu
/// anlamiyordu.
///
/// UYGULAMA NOTU: Flame'in hazir efekt sistemi kullanildi
/// ([ScaleEffect], [OpacityEffect], [RemoveEffect]); buyume/solma elle
/// `update` icinde hesaplanmadi. Efektler bir `Component` oldugu icin oyun
/// duraklatildiginda (`pauseEngine`) kendiliginden dururlar.
///
/// [RemoveEffect]: efekt bitince component agactan KENDINI cikarir. Yapilmasa
/// her patlama ekranda gorunmez sekilde birikir (bellek sizintisi).
///
/// CircleComponent, `HasPaint` uzerinden [OpacityProvider] sagladigi icin
/// opaklik efekti dogrudan uygulanabiliyor
/// (bkz. flame/src/geometry/shape_component.dart:9).
class ExplosionComponent extends CircleComponent {
  ExplosionComponent({
    required Vector2 explosionPosition,
    required double explosionRadius,
    required Color explosionColor,
  }) : super(
         position: explosionPosition,
         radius: explosionRadius,
         anchor: Anchor.center,
         // Her seyin ONUNDE cizilir: patlama oyuncunun/dusmanin ustunde gorunur.
         priority: 20,
         paint: Paint()..color = explosionColor,
       );

  /// SENKRON `onLoad` (bilincli).
  ///
  /// `Future<void> onLoad() async` yazilip `await addAll(...)` yapilirsa
  /// component'in yuklenmesi bir sonraki olay dongusu turuna kalir. Flame'in
  /// yasam dongusu kuyrugu SIRAYLA islendigi icin, bu component kuyruktaysa
  /// ARKASINDAKI tum eklemeler de bekler. Efektleri eklemek icin beklemeye
  /// gerek yoktur; senkron tutmak component'in ayni karede hazir olmasini
  /// saglar ve kuyrugu tikamaz.
  @override
  void onLoad() {
    addAll(<Component>[
      // easeOut: patlama hizli baslar, yavaslayarak durur -- ani bir darbe
      // hissi verir. Dogrusal buyume mekanik gorunurdu.
      ScaleEffect.to(
        Vector2.all(GameConfig.explosionScaleTarget),
        EffectController(
          duration: GameConfig.explosionDuration,
          curve: Curves.easeOut,
        ),
      ),
      OpacityEffect.fadeOut(
        EffectController(duration: GameConfig.explosionDuration),
      ),
      RemoveEffect(delay: GameConfig.explosionDuration),
    ]);
  }
}
