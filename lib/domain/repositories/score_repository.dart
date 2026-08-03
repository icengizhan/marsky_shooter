import '../entities/score_entry.dart';

/// Skor kaliciligi icin SOZLESME (arayuz). Implementasyonu `data/` katmanindadir.
///
/// Bu ayrim SOLID'in "D"si olan Dependency Inversion'in uygulamasidir:
/// oyun ve UI katmani `SharedPreferences`i degil bu arayuzu bilir. Boylece
/// depolama teknolojisi degistiginde (ornegin ileride bir sunucuya tasinsa)
/// oyun kodunun tek satiri bile degismez, sadece yeni bir implementasyon yazilir.
///
/// `abstract interface class`: yalnizca `implements` ile kullanilabilir,
/// `extends` edilemez. Sozlesme oldugunu dilin kendisiyle beyan eder. (Dart 3)
abstract interface class ScoreRepository {
  /// Kayitli en yuksek skoru dondurur. Hic kayit yoksa 0.
  Future<int> readHighScore();

  /// Verilen skor mevcut rekordan yuksekse kaydeder ve `true` doner.
  /// Yuksek degilse hicbir sey yazmaz ve `false` doner.
  Future<bool> writeHighScoreIfHigher(int points);

  /// En yeniden en eskiye dogru sirali skor gecmisi.
  Future<List<ScoreEntry>> readHistory();

  /// Gecmise yeni bir kayit ekler.
  /// Liste [GameConfig.maxScoreHistoryEntries] uzunlugunda tutulur.
  Future<void> appendToHistory(ScoreEntry entry);
}
