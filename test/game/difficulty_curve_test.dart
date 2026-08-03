import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/core/config/game_config.dart';
import 'package:marsky_shooter/game/managers/difficulty_curve.dart';

void main() {
  group('DifficultyCurve', () {
    test('oyun basinda aralik yapilandirmadaki degerlerdir', () {
      final ({double min, double max}) range =
          DifficultyCurve.spawnIntervalRange(0);

      expect(range.min, closeTo(GameConfig.spawnIntervalMin, 0.0001));
      expect(range.max, closeTo(GameConfig.spawnIntervalMax, 0.0001));
    });

    test('zaman ilerledikce aralik kisalir (oyun zorlasir)', () {
      final ({double min, double max}) atStart =
          DifficultyCurve.spawnIntervalRange(0);
      final ({double min, double max}) atOneMinute =
          DifficultyCurve.spawnIntervalRange(60);

      expect(atOneMinute.max, lessThan(atStart.max));
      expect(atOneMinute.min, lessThanOrEqualTo(atStart.min));
    });

    test('taban degerin altina inmez (oyun oynanamaz hale gelmez)', () {
      final ({double min, double max}) veryLate =
          DifficultyCurve.spawnIntervalRange(10000);

      expect(veryLate.min, greaterThanOrEqualTo(GameConfig.spawnIntervalFloor));
      expect(veryLate.max, greaterThanOrEqualTo(GameConfig.spawnIntervalFloor));
    });

    test('min her zaman max degerinden kucuk veya esittir', () {
      for (final double t in <double>[0, 5, 15, 45, 120, 600]) {
        final ({double min, double max}) range =
            DifficultyCurve.spawnIntervalRange(t);
        expect(range.min, lessThanOrEqualTo(range.max), reason: 't = $t');
      }
    });
  });
}
