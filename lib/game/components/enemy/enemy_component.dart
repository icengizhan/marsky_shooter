import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/config/game_config.dart';
import '../../marsky_game.dart';
import '../effects/explosion_component.dart';
import '../play_area_bounds.dart';

/// Ekranin ustunde olusup OYUNCUYA DOGRU inen dusman.
///
/// Yon vektoru olusma aninda hesaplanip sabitlenir (dalis manevrasi gibi).
/// Her karede yeniden hedeflemek yerine bunun secilmesi bilinclidir:
/// (1) oyuncu kacabilir, yoksa dusman kacinilmaz sekilde takip eder ve oyun
/// adil olmaz, (2) davranis deterministik olur, testte dogrulanabilir.
///
/// GERI DONUSTURULUR: ekrandan cikan veya vurulan dusman silinmek yerine
/// Flame'in `ComponentPool`una doner (bkz. `MarskyGame.enemyPool`). Bu yuzden
/// constructor parametreleri zorunlu degildir -- havuz nesneyi parametresiz
/// uretir, ardindan [reset] cagrilir.
class EnemyComponent extends SpriteComponent with HasGameReference<MarskyGame> {
  EnemyComponent({Vector2? spawnPosition, Vector2? velocity})
    : velocity = velocity ?? Vector2.zero(),
      super(
        position: spawnPosition ?? Vector2.zero(),
        size: Vector2(GameConfig.enemyWidth, GameConfig.enemyHeight),
        anchor: Anchor.center,
        priority: 6,
      );

  /// Saniyedeki yer degistirme (piksel/saniye). Olusma aninda hesaplanir,
  /// sonra degismez. Test bu degeri okuyarak yonu dogrulayabilir.
  ///
  /// `final` DEGIL cunku havuzdan yeniden kullanilirken [reset] ile guncellenir;
  /// ancak vektorun KENDISI degistirilir (`setFrom`), referans degismez.
  final Vector2 velocity;

  bool _isDying = false;

  /// Havuzdan alinan dusmani yeni bir dalis icin hazirlar.
  ///
  /// `_isDying` sifirlanmasi KRITIK: yeniden kullanilan bir dusman "olu"
  /// isaretli kalirsa mermiler ona isabet etmez ve oyun sessizce bozulur.
  void reset({required Vector2 spawnPosition, required Vector2 newVelocity}) {
    position.setFrom(spawnPosition);
    velocity.setFrom(newVelocity);
    _isDying = false;
  }

  /// Ayni karede iki merminin ayni dusmani vurup iki kez puan kazandirmasini
  /// engellemek icin kullanilir.
  bool get isDying => _isDying;

  /// Senkron `onLoad` (bilincli) -- gerekcesi `ExplosionComponent`'te anlatildi.
  @override
  void onLoad() {
    sprite = Sprite(game.images.fromCache(GameAssets.enemy));

    // CircleHitbox: sprite bir elmas/yildiz seklinde oldugu icin daire,
    // dikdortgenden daha dogru bir yaklasim -- kose bosluklarinda haksiz
    // carpisma olmaz. Daire kesisimi ayrica dikdortgenden daha az islem ister.
    //
    // CollisionType.passive: dusmanlar birbirini KONTROL ETMEZ. Yalnizca
    // `active` hitbox'lar (oyuncu ve mermi) tarama baslatir. 20 dusman
    // varken active olsalardi her karede ~190 gereksiz cift kontrol edilirdi.
    // (case PDF §3: "Hitbox ... mekanizmaları performanslı bir şekilde")
    //
    // isSolid: true ZORUNLU. Varsayilan `false`, sekli "ici bos halka" gibi
    // ele alir: carpisma yalnizca KENARLAR kesistiginde bulunur. Kucuk mermi
    // hitbox'i dusman dairesinin tamamen icine girdiginde hicbir kenar
    // kesismez ve isabet KAYDEDILMEZ. `isSolid` ile kapsanma durumu da
    // carpisma sayilir (bkz. flame/src/geometry/shape_intersections.dart:85).
    add(
      CircleHitbox(
        radius: size.x * 0.42,
        position: size / 2,
        anchor: Anchor.center,
        isSolid: true,
        collisionType: CollisionType.passive,
      ),
    );
  }

  /// Mermi isabetinde cagrilir.
  void takeHit() {
    if (_isDying) {
      return;
    }
    _isDying = true;

    // Patlama dusmanin DEGIL, dunyanin cocugu olarak eklenir: dusman hemen
    // agactan cikarildigi icin cocugu olsaydi patlama da aninda silinirdi.
    parent?.add(
      ExplosionComponent(
        explosionPosition: position.clone(),
        explosionRadius: GameConfig.enemyExplosionRadius,
        explosionColor: GameConfig.enemyExplosionColor,
      ),
    );
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Hareket her zaman `dt` ile olceklenir -> FPS'ten bagimsiz hiz.
    position += velocity * dt;

    // Ekran disina cikan dusman temizlenir (ve havuza doner).
    // Yanlar da kontrol edilir: nisan sapmasi yuzunden capraz inen bir dusman
    // yana savrulabilir ve yalnizca alt sinira bakilirsa gereksizce yasar.
    if (isBelowPlayArea || isBesidePlayArea) {
      removeFromParent();
    }
  }
}
