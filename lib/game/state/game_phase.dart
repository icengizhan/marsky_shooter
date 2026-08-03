/// Oyunun bulundugu durum (state).
///
/// Case PDF §2.B'de istenen dort durum birebir karsilanir. Bu bir `enum`
/// oldugu icin gecersiz bir duruma girmek imkansizdir -- `bool isPaused`,
/// `bool isGameOver` gibi ayri bayraklar kullanilsaydi "hem duraklatilmis hem
/// oyun bitmis" gibi anlamsiz kombinasyonlar olusabilirdi.
enum GamePhase {
  /// Ana menu: Basla butonu ve en yuksek skor.
  menu,

  /// Aktif oynanis.
  playing,

  /// Duraklatildi; motor durur, devam edilebilir.
  paused,

  /// Carpisma sonrasi; son skor gosterilir, yeniden baslanabilir.
  gameOver,
}
