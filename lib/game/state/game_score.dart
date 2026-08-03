import 'package:flutter/foundation.dart';

import '../../core/config/game_config.dart';

/// Anlik skoru tutar.
///
/// NEDEN `ValueNotifier`, NEDEN RIVERPOD DEGIL:
/// Skor saniyede onlarca kez degisir. Riverpod/Bloc gibi bir cozume baglanip
/// her degisimde widget agacini yeniden kurmak 60 FPS'i dusurur. `ValueNotifier`
/// + `ValueListenableBuilder` ikilisi yalnizca skor METNINI yeniden cizer.
/// Oyun DISI state (yuksek skor, ses ayari) Riverpod'da tutulur -- bkz. Faz 7.
///
/// Sinif Flame'den bagimsizdir; skor mantigi oyunu ayaga kaldirmadan test edilir.
class GameScore {
  /// Dinlenebilir anlik skor.
  final ValueNotifier<int> points = ValueNotifier<int>(0);

  /// Henuz tam saniyeye ulasmamis artik sure.
  double _survivalRemainder = 0;

  /// Hayatta kalinan sureye gore puan ekler.
  ///
  /// `dt` degerleri kesirli oldugu icin biriktirilir; her tam saniyede puan
  /// verilir. Dogrudan `dt` eklenip yuvarlanirsa yuksek FPS'te daha fazla puan
  /// kazanilir ve skor cihaza gore adaletsiz olur.
  void addSurvivalTime(double dt) {
    _survivalRemainder += dt;
    while (_survivalRemainder >= 1.0) {
      _survivalRemainder -= 1.0;
      points.value += GameConfig.scorePerSecond;
    }
  }

  void addEnemyKill() {
    points.value += GameConfig.scorePerEnemyKilled;
  }

  void addPickupCollected() {
    points.value += GameConfig.scorePerPickupCollected;
  }

  void reset() {
    points.value = 0;
    _survivalRemainder = 0;
  }

  void dispose() {
    points.dispose();
  }
}
