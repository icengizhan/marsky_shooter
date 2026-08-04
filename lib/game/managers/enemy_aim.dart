import 'dart:math';

import 'package:flame/components.dart';

/// Dusmanin hiz vektoru hesabi.
///
/// Spawner'in icinde birakilmadi: bu saf bir matematik islemi ve tek basina
/// dogrulanabilir olmasi gerekir ("sapma sifirken tam hedefe gidiyor mu",
/// "sapma hiz buyuklugunu bozuyor mu"). Oyun dongusunu simule etmeden test
/// edilebilir.
abstract final class EnemyAim {
  /// [spawnPosition]'dan [targetPosition]'a dogru, [deviationRadians] kadar
  /// sapmis, buyuklugu [speed] olan hiz vektoru dondurur.
  ///
  /// Aci uzerinden hesaplanir cunku yonu degistirirken hiz BUYUKLUGUNU
  /// korumanin en net yolu budur. Vektore dogrudan bir sapma eklenirse hem
  /// yon hem hiz degisir ve dusmanlar ongorulemez hizlarda inerdi.
  static Vector2 velocityToward({
    required Vector2 spawnPosition,
    required Vector2 targetPosition,
    required double speed,
    double deviationRadians = 0,
  }) {
    final Vector2 toTarget = targetPosition - spawnPosition;
    final double angle = atan2(toTarget.y, toTarget.x) + deviationRadians;
    return Vector2(cos(angle), sin(angle)) * speed;
  }
}
