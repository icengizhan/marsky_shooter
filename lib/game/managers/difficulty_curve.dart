import 'dart:math';

import '../../core/config/game_config.dart';

/// Zorluk egrisi: gecen sureye gore dusman olusma (spawn) araligini hesaplar.
///
/// Bilincli olarak SAF DART: ne Flame ne Flutter bilir. Boylece oyunu ayaga
/// kaldirmadan, duz bir unit test ile "30. saniyede aralik gercekten kisaliyor
/// mu", "taban degerin altina dusuyor mu" gibi sorular dogrulanabilir.
/// Bu mantik spawner'in icine gomulu olsa, test etmek icin tum oyun dongusunu
/// simule etmek gerekirdi.
abstract final class DifficultyCurve {
  /// [elapsedSeconds] anindaki spawn araligi alt/ust siniri (saniye).
  ///
  /// Her [GameConfig.difficultyStepSeconds] saniyede aralik
  /// [GameConfig.difficultyStepFactor] ile carpilir (yani kisalir), ancak
  /// [GameConfig.spawnIntervalFloor] degerinin altina inmez -- aksi halde oyun
  /// bir sure sonra oynanamaz hale gelirdi.
  static ({double min, double max}) spawnIntervalRange(double elapsedSeconds) {
    final double steps = elapsedSeconds / GameConfig.difficultyStepSeconds;
    final double scale = pow(GameConfig.difficultyStepFactor, steps).toDouble();

    final double minInterval = max(
      GameConfig.spawnIntervalMin * scale,
      GameConfig.spawnIntervalFloor,
    );
    final double maxInterval = max(
      GameConfig.spawnIntervalMax * scale,
      GameConfig.spawnIntervalFloor,
    );

    return (min: minInterval, max: maxInterval);
  }
}
