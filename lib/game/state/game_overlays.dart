/// Overlay kimlikleri.
///
/// Flame overlay'leri `String` anahtarla yonetir. Bu anahtarlari cagri
/// yerlerine elle yazmak, bir harf hatasinda sessizce hicbir seyin
/// gorunmemesine yol acar -- derleyici yakalamaz. Sabitler bu riski ortadan
/// kaldirir.
///
/// Bu dosya bilincli olarak `game/` altindadir: overlay'i AKTIVE eden taraf
/// oyun motorudur (`game.overlays`), sunum katmani yalnizca hangi widget'in
/// hangi kimlige karsilik geldigini kaydeder. Ters yonde bir bagimlilik
/// (oyunun `presentation/`i import etmesi) katman siralamasini bozardi.
abstract final class GameOverlays {
  static const String mainMenu = 'main_menu';
  static const String hud = 'hud';
  static const String pause = 'pause';
  static const String gameOver = 'game_over';
}
