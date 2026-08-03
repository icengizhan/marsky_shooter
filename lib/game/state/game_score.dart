import 'package:flutter/foundation.dart';

import '../../core/config/game_config.dart';

/// Bir oyunun skor dokumu. Oyun bitti ekrani bunu gosterir.
///
/// `typedef` + record kullanildi: yalnizca veri tasiyan, davranissiz bir yapi
/// icin ayri bir sinif yazmak gereksiz kod olurdu.
typedef ScoreBreakdown = ({
  int survivalSeconds,
  int enemiesDestroyed,
  int pickupsCollected,
  int total,
});

/// Anlik skoru ve kaynak dokumunu tutar.
///
/// NEDEN `ValueNotifier`, NEDEN RIVERPOD DEGIL:
/// Skor saniyede onlarca kez degisir. Riverpod/Bloc gibi bir cozume baglanip
/// her degisimde widget agacini yeniden kurmak 60 FPS'i dusurur. `ValueNotifier`
/// + `ValueListenableBuilder` ikilisi yalnizca skor METNINI yeniden cizer.
/// Oyun DISI state (yuksek skor, ses ayari) Riverpod'da tutulur -- bkz. Faz 7.
///
/// Sinif Flame'den bagimsizdir; skor mantigi oyunu ayaga kaldirmadan test edilir.
class GameScore {
  /// Dinlenebilir anlik toplam skor.
  final ValueNotifier<int> points = ValueNotifier<int>(0);

  /// Henuz tam saniyeye ulasmamis artik sure.
  double _survivalRemainder = 0;

  int _survivalSeconds = 0;
  int _enemiesDestroyed = 0;
  int _pickupsCollected = 0;

  /// Oyun sonunda gosterilecek dokum.
  ///
  /// Anlik deger okumak yerine kopya alinir: `reset()` sonrasi sayaclar
  /// sifirlanacagi icin oyun bitti ekrani kendi kopyasini saklamalidir.
  ScoreBreakdown get breakdown => (
    survivalSeconds: _survivalSeconds,
    enemiesDestroyed: _enemiesDestroyed,
    pickupsCollected: _pickupsCollected,
    total: points.value,
  );

  /// Hayatta kalinan sureye gore puan ekler.
  ///
  /// `dt` degerleri kesirli oldugu icin biriktirilir; her tam saniyede puan
  /// verilir. Dogrudan `dt` eklenip yuvarlanirsa yuksek FPS'te daha fazla puan
  /// kazanilir ve skor cihaza gore adaletsiz olur.
  void addSurvivalTime(double dt) {
    _survivalRemainder += dt;
    while (_survivalRemainder >= 1.0) {
      _survivalRemainder -= 1.0;
      _survivalSeconds++;
      points.value += GameConfig.scorePerSecond;
    }
  }

  void addEnemyKill() {
    _enemiesDestroyed++;
    points.value += GameConfig.scorePerEnemyKilled;
  }

  void addPickupCollected() {
    _pickupsCollected++;
    points.value += GameConfig.scorePerPickupCollected;
  }

  void reset() {
    points.value = 0;
    _survivalRemainder = 0;
    _survivalSeconds = 0;
    _enemiesDestroyed = 0;
    _pickupsCollected = 0;
  }

  void dispose() {
    points.dispose();
  }
}
