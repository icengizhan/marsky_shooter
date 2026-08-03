import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/painting.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/config/game_config.dart';

/// Iki katmanli kayan yildiz alani (parallax arka plan).
///
/// Flame'in hazir [ParallaxComponent]'i kullanilir; katman kaydirmayi elle
/// hesaplamak gereksiz kod ve hata kaynagi olurdu.
///
/// Derinlik hissi `velocityMultiplierDelta` ile olusur: yakin katman uzak
/// katmandan daha hizli kayar -- gercek dunyada da yakin nesneler goz onunden
/// daha hizli gecer.
///
/// ParallaxComponent (Flame — https://docs.flame-engine.org/latest/flame/parallax.html)
Future<ParallaxComponent<dynamic>> createStarfieldBackground(
  Images imageCache,
) {
  return ParallaxComponent.load(
    <ParallaxData>[
      ParallaxImageData(GameAssets.starsFar),
      ParallaxImageData(GameAssets.starsNear),
    ],
    baseVelocity: Vector2(0, GameConfig.starfieldBaseVelocity),
    velocityMultiplierDelta: Vector2(1, GameConfig.starfieldLayerDelta),
    // Yildiz doku (texture) her iki eksende doseneir; olceklenmez, boylece
    // yildizlar buyuyup bulaniklasmaz.
    repeat: ImageRepeat.repeat,
    fill: LayerFill.none,
    alignment: Alignment.topLeft,
    // Onceden doldurulmus onbellek verilir; parallax kendi basina yeniden
    // yukleme yapmaz.
    images: imageCache,
    position: Vector2.zero(),
    size: Vector2(GameConfig.designWidth, GameConfig.designHeight),
    // Negatif priority: her seyin ARKASINDA cizilir.
    priority: -10,
  );
}
