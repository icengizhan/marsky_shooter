import 'package:flame/components.dart';

import '../../core/config/game_config.dart';

/// Oyun alani sinir kontrolleri.
///
/// Uc component (mermi, dusman, elmas) "ekran disina cikti mi" sorusunu soruyor.
/// Sorunun CEVABI tek yerde toplanir: anchor sozlesmesi (merkez) veya tasarim
/// yuksekligi degistiginde tek dosya guncellenir.
///
/// NEDEN MIXIN DEGIL DE EXTENSION:
/// Mixin secenegi degerlendirildi ve REDDEDILDI. Uc component'in kosullari
/// birbirinden farkli (mermi USTTEN, dusman ve elmas ALTTAN cikar); mixin ile
/// birlestirmek icin bir enum + her sinifa soyut bir getter eklemek gerekirdi.
/// Bu, kazandirdigi 3 satirdan daha fazla dolayli yapi demekti. Extension ise
/// kalitim iliskisi kurmadan yalnizca okunabilir bir isim veriyor.
extension PlayAreaBounds on PositionComponent {
  /// Component tamamen ekranin USTUNDEN cikti mi.
  bool get isAbovePlayArea => position.y + size.y < 0;

  /// Component tamamen ekranin ALTINDAN cikti mi.
  bool get isBelowPlayArea => position.y - size.y > GameConfig.designHeight;

  /// Component tamamen ekranin SAGINDAN veya SOLUNDAN cikti mi.
  ///
  /// Dusmanlar nisan sapmasi yuzunden capraz iner; yana savrulan bir dusman
  /// yalnizca alt sinir kontrol edilirse ekran disinda uzun sure yasar ve
  /// bosuna `update` alir. Bu kontrol onu da temizler.
  bool get isBesidePlayArea =>
      position.x + size.x < 0 || position.x - size.x > GameConfig.designWidth;
}
