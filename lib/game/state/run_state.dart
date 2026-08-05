import 'package:flutter/foundation.dart';

import '../../core/config/game_config.dart';

/// Tek bir oyun KOSUSUNUN gucu: kalan can, silah seviyesi ve zorluk seviyesi.
///
/// NEDEN [GameScore]'DAN AYRI: skor bir SONUCTUR, bunlar oyunun anlik
/// GUCUDUR. Ikisini tek sinifa koymak "skor" adini yalancı yapardi ve oyun
/// bitti ekraninin kopyaladigi dokum gereksizce buyurdu. Ayrilmalarinin somut
/// faydasi: bu sinif Flame'i de Flutter widget'ini de bilmedigi icin oyunu
/// ayaga kaldirmadan test edilebiliyor.
///
/// NEDEN `MarskyGame` ICINDE ALAN OLARAK DEGIL: kok sinif zaten kompozisyon,
/// faz gecisi ve havuzlari tasiyor. Uc `ValueNotifier` daha eklemek onu
/// davranis tasiyan bir sinifa dogru kaydiriyordu.
class RunState {
  /// Kalan can. HUD bunu dinler.
  final ValueNotifier<int> lives = ValueNotifier<int>(
    GameConfig.playerMaxLives,
  );

  /// Silah seviyesi (1 = tek mermi). Elmas topladikca artar, vurulunca duser.
  final ValueNotifier<int> weaponLevel = ValueNotifier<int>(1);

  /// Zorluk seviyesi. Gecen sureden TURETILIR, elle artirilmaz.
  final ValueNotifier<int> level = ValueNotifier<int>(1);

  bool get isAlive => lives.value > 0;

  /// Silah seviyesi tavana ulasti mi (HUD "MAX" gosterebilir).
  bool get isWeaponMaxed => weaponLevel.value >= GameConfig.maxWeaponLevel;

  /// Bu seviyede tek atesle cikan mermi sayisi.
  ///
  /// Seviye 4 mermi sayisini artirmaz, ates HIZINI artirir (bkz.
  /// [fireCooldown]). Boylece ekran mermi ile dolup carpisma taramasi
  /// gereksiz buyumez; yukselme hissi hizdan gelir.
  int get bulletsPerShot => switch (weaponLevel.value) {
    1 => 1,
    2 => 2,
    _ => 3,
  };

  /// Bu seviyedeki ates araligi.
  double get fireCooldown => weaponLevel.value >= 4
      ? GameConfig.fireCooldown * GameConfig.maxLevelFireRateFactor
      : GameConfig.fireCooldown;

  /// Elmas toplandi: silah bir kademe yukselir (tavana kadar).
  ///
  /// `true` donerse gercekten yukseldi; cagiran taraf buna gore ses/efekt
  /// oynatabilir. Tavandayken elmas yine puan verir ama seviye degismez.
  bool upgradeWeapon() {
    if (isWeaponMaxed) {
      return false;
    }
    weaponLevel.value++;
    return true;
  }

  /// Bir vurus alindi. Kalan can dondurulur.
  ///
  /// Silah seviyesi bir kademe DUSER ama 1'in altina inmez: ceza hissedilir
  /// olmali ama oyuncuyu silahsiz birakmamali, yoksa son can bir ceza degil
  /// mahkumiyet olur.
  int takeHit() {
    if (lives.value > 0) {
      lives.value--;
    }
    if (weaponLevel.value > 1) {
      weaponLevel.value--;
    }
    return lives.value;
  }

  /// Gecen sureye gore zorluk seviyesini gunceller.
  ///
  /// `true` donerse seviye ATLADI; cagiran taraf banner gosterip spawn'a kisa
  /// bir nefes verir. Seviye burada TURETILIYOR, ayri bir sayacla
  /// takip edilmiyor -- iki kaynak olsa zorluk egrisi ile gosterge birbirinden
  /// ayrilabilirdi.
  bool syncLevel(double elapsedSeconds) {
    final int computed =
        (elapsedSeconds / GameConfig.difficultyStepSeconds).floor() + 1;
    if (computed <= level.value) {
      return false;
    }
    level.value = computed;
    return true;
  }

  void reset() {
    lives.value = GameConfig.playerMaxLives;
    weaponLevel.value = 1;
    level.value = 1;
  }

  void dispose() {
    lives.dispose();
    weaponLevel.dispose();
    level.dispose();
  }
}
