import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/game/managers/enemy_aim.dart';

void main() {
  group('EnemyAim', () {
    test('sapma yokken tam hedefe dogru gider', () {
      final Vector2 velocity = EnemyAim.velocityToward(
        spawnPosition: Vector2(100, 0),
        targetPosition: Vector2(100, 200),
        speed: 50,
      );

      // Tam asagi: x sifir, y pozitif.
      expect(velocity.x, closeTo(0, 0.0001));
      expect(velocity.y, closeTo(50, 0.0001));
    });

    test('hiz buyuklugu her zaman korunur (sapma bozmaz)', () {
      for (final double deviation in <double>[-0.5, -0.2, 0, 0.2, 0.5]) {
        final Vector2 velocity = EnemyAim.velocityToward(
          spawnPosition: Vector2(30, 0),
          targetPosition: Vector2(240, 680),
          speed: 120,
          deviationRadians: deviation,
        );

        expect(
          velocity.length,
          closeTo(120, 0.0001),
          reason: 'sapma $deviation ile hiz degismemeli',
        );
      }
    });

    test('sapma yonu tam olarak verilen aci kadar dondurur', () {
      const double deviation = 0.3;
      final Vector2 exact = EnemyAim.velocityToward(
        spawnPosition: Vector2(0, 0),
        targetPosition: Vector2(0, 100),
        speed: 10,
      );
      final Vector2 deviated = EnemyAim.velocityToward(
        spawnPosition: Vector2(0, 0),
        targetPosition: Vector2(0, 100),
        speed: 10,
        deviationRadians: deviation,
      );

      final double exactAngle = atan2(exact.y, exact.x);
      final double deviatedAngle = atan2(deviated.y, deviated.x);

      expect(deviatedAngle - exactAngle, closeTo(deviation, 0.0001));
    });

    test('yatay sapmaya ragmen dusman asagi inmeye devam eder', () {
      // Ekranin ustunden (y=-40) oyuncuya (y=680) dogru, en buyuk sapma ile.
      for (final double deviation in <double>[-0.35, 0.35]) {
        final Vector2 velocity = EnemyAim.velocityToward(
          spawnPosition: Vector2(20, -40),
          targetPosition: Vector2(460, 680),
          speed: 100,
          deviationRadians: deviation,
        );

        expect(
          velocity.y,
          greaterThan(0),
          reason: 'sapma $deviation ile dusman yukari gitmemeli',
        );
      }
    });
  });
}
