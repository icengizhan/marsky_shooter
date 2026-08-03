import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../marsky_game.dart';

/// "Rastgele araliklarla nesne olustur" iskeleti.
///
/// Dusman ve toplanabilir nesne olusturucularinin ortak davranisi burada
/// toplanir: sayac tutma, oynanis disinda durma, sifirlama. Alt siniflar
/// yalnizca IKI soruyu cevaplar -- "sonraki gecikme ne kadar" ve "ne olustur".
///
/// Bu ayrim olmasa iki spawner ayni sayac mantigini kopyalardi ve bir hata
/// duzeltmesi iki yerde yapilmak zorunda kalirdi (Template Method deseni).
abstract class IntervalSpawner extends Component
    with HasGameReference<MarskyGame> {
  /// [random] disaridan verilebilir: testte sabit tohumlu bir [Random]
  /// gecirilerek davranis deterministik hale getirilir.
  IntervalSpawner({Random? random}) : random = random ?? Random();

  @protected
  final Random random;

  /// Oyun basindan bu yana gecen sure. Zorluk egrisi kullanan alt siniflar
  /// icin gereklidir.
  @protected
  double get elapsed => _elapsed;
  double _elapsed = 0;

  /// Sonraki olusuma kalan sure.
  double _countdown = 0;

  /// Sonraki olusuma kadar beklenecek sure (saniye).
  @protected
  double nextInterval();

  /// Nesneyi sahneye ekler.
  @protected
  void spawnOne();

  @override
  Future<void> onLoad() async {
    _countdown = nextInterval();
  }

  /// Yeni oyun icin sayaclari sifirlar.
  void reset() {
    // Sira onemli: `nextInterval()` gecen sureye bagli olabilir, bu yuzden
    // once `_elapsed` sifirlanir.
    _elapsed = 0;
    _countdown = nextInterval();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Ana menude ve oyun bitti ekraninda uretim durur. Motor calismaya devam
    // ettigi icin (yildizlar kaysin diye) bu kontrol gereklidir.
    if (!game.isPlaying) {
      return;
    }

    _elapsed += dt;
    _countdown -= dt;
    if (_countdown > 0) {
      return;
    }
    _countdown = nextInterval();
    spawnOne();
  }

  /// [min] - [max] arasinda rastgele bir sure. Alt siniflar icin kolaylik.
  @protected
  double randomBetween(double min, double max) =>
      min + (random.nextDouble() * (max - min));
}
