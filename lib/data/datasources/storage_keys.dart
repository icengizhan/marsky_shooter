/// Kalici depoda kullanilan TUM anahtarlar.
///
/// NEDEN TEK YERDE: anahtarlar dagilirsa iki ayri yerde ayni ismin kullanilmasi
/// (veri ezilmesi) veya bir anahtarin degistirilip digerinin unutulmasi
/// (kullanicinin kaydi kaybolur) sessiz hatalar dogurur. Tek dosyada durunca
/// cakisma gozle gorulur.
///
/// `marsky.` oneki: ayni cihazdaki baska uygulama verileriyle karismamasi icin.
abstract final class StorageKeys {
  static const String highScore = 'marsky.high_score';
  static const String scoreHistory = 'marsky.score_history';
  static const String soundEnabled = 'marsky.sound_enabled';
}
