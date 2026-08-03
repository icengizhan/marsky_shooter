import 'package:flame/components.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/config/game_config.dart';
import '../../marsky_game.dart';
import '../projectile/bullet_component.dart';

/// Oyuncunun gemisi.
///
/// Sorumlulugu iki sey: hedef konuma yumusak sekilde yaklasmak ve belirli
/// arayla ates etmek. Girdiyi KENDISI toplamaz -- disaridan [nudge] cagrilir
/// (bkz. `DragInputComponent`). Bu ayrim sayesinde oyuncu, kontrol yonteminden
/// bagimsizdir.
class PlayerComponent extends SpriteComponent with HasGameReference<MarskyGame> {
  PlayerComponent()
    : super(
        size: Vector2(GameConfig.playerWidth, GameConfig.playerHeight),
        anchor: Anchor.center,
        priority: 10,
      );

  /// Geminin yaklasmaya calistigi konum. Surukleme bunu oteler, gemi pesinden
  /// gelir. Dogrudan `position`i degistirmek yerine hedef kullanilmasi hareketi
  /// yumusatir ve titremeyi (jitter) onler.
  final Vector2 _target = Vector2.zero();

  double _fireCooldown = 0;

  @override
  Future<void> onLoad() async {
    sprite = Sprite(game.images.fromCache(GameAssets.player));
    position = Vector2(
      GameConfig.designWidth / 2,
      GameConfig.designHeight - GameConfig.playerBottomMargin,
    );
    _target.setFrom(position);
  }

  /// Hedefi [delta] kadar oteler ve oyun alani icinde tutar.
  void nudge(Vector2 delta) {
    _target.add(delta);
    _clampTargetToScreen();
  }

  /// Gemiyi baslangic konumuna dondurur (yeniden baslatma icin).
  void resetToStart() {
    position = Vector2(
      GameConfig.designWidth / 2,
      GameConfig.designHeight - GameConfig.playerBottomMargin,
    );
    _target.setFrom(position);
    _fireCooldown = 0;
  }

  void _clampTargetToScreen() {
    final double halfWidth = (size.x / 2) + GameConfig.playerEdgePadding;
    final double halfHeight = (size.y / 2) + GameConfig.playerEdgePadding;
    _target.x = _target.x.clamp(
      halfWidth,
      GameConfig.designWidth - halfWidth,
    );
    _target.y = _target.y.clamp(
      halfHeight,
      GameConfig.designHeight - halfHeight,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _followTarget(dt);
    _updateFiring(dt);
  }

  void _followTarget(double dt) {
    // Oransal yaklasma (exponential smoothing). `dt` ile carpildigi icin
    // yumusama hizi FPS'ten bagimsizdir. clamp(0,1) buyuk `dt` degerlerinde
    // (kare atlamasi) hedefi asmayi (overshoot) onler.
    final double t = (GameConfig.playerFollowSpeed * dt).clamp(0.0, 1.0);
    position += (_target - position) * t;
  }

  void _updateFiring(double dt) {
    _fireCooldown -= dt;
    if (_fireCooldown > 0) {
      return;
    }
    _fireCooldown = GameConfig.fireCooldown;
    _fire();
  }

  void _fire() {
    // Mermi oyuncunun DEGIL, oyuncunun ebeveyninin (dunyanin) cocugu olarak
    // eklenir. Oyuncunun cocugu olsaydi, oyuncu ile birlikte hareket eder ve
    // oyuncu yok edildiginde mermiler de aninda kaybolurdu.
    parent?.add(
      BulletComponent(spawnPosition: position - Vector2(0, size.y / 2)),
    );
    // Ses dogrudan FlameAudio'ya degil, oyunun ses kapisina gider. Boylece
    // mute ayari ve testlerde sessiz mod tek yerden yonetilir.
    game.audio.playShoot();
  }
}
