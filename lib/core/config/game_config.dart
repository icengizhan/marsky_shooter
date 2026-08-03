import 'dart:ui';

/// Oyunun tum ayarlanabilir sayilari tek yerde toplanir.
///
/// Neden: "sihirli sayilar" (magic numbers) component sinifllarinin icine
/// dagilirsa oyun dengesini ayarlamak icin 10 ayri dosya acmak gerekir.
/// Burada toplanmasi hem okunabilirligi hem de test edilebilirligi artirir --
/// testler bu degerleri okuyarak beklenen davranisi dogrular.
///
/// `abstract final class`: ornegi olusturulamaz, alt sinifi turetilemez.
/// Sadece sabit tasiyici olarak kullanilir. (Dart 3 class modifiers)
abstract final class GameConfig {
  // ---------------------------------------------------------------- gorunum
  /// Uzay arka plan rengi. FlameGame.backgroundColor() bunu dondurur.
  static const Color spaceColor = Color(0xFF05060F);

  /// Referans tasarim genisligi. Kamera bu genislige gore olceklenir, boylece
  /// oyun her ekran oraninda ayni oynanis alanini gosterir.
  static const double designWidth = 480;
  static const double designHeight = 800;

  // ------------------------------------------------------------- arka plan
  /// Yildiz katmanlarinin temel kayma hizi (piksel/saniye, +y = asagi).
  /// Yildizlar asagi kayar -> geminin yukari uctugu hissi olusur.
  static const double starfieldBaseVelocity = 22;

  /// Katmanlar arasi hiz carpani. Yakin katman uzak katmandan bu kat hizli
  /// kayar -> derinlik (parallax) hissi. 1.0 olsa katmanlar ayni hizda kayar
  /// ve parallax etkisi kaybolurdu.
  static const double starfieldLayerDelta = 2.2;

  // ---------------------------------------------------------------- oyuncu
  static const double playerWidth = 48;
  static const double playerHeight = 48;

  /// Oyuncunun ekranin altindan yukseklik payi.
  static const double playerBottomMargin = 120;

  /// Surukleme sirasinda oyuncunun hedefe ne kadar hizli yaklasacagi.
  /// Dogrudan parmagin altina "zipla" yerine yumusak takip icin kullanilir.
  static const double playerFollowSpeed = 18;

  /// Oyuncunun ekran kenarlarina yaklasabilecegi minimum mesafe.
  static const double playerEdgePadding = 8;

  // ---------------------------------------------------------------- mermi
  static const double bulletWidth = 6;
  static const double bulletHeight = 16;
  static const double bulletSpeed = 520;

  /// Iki ates arasindaki bekleme (saniye). Otomatik ates hizini belirler.
  static const double fireCooldown = 0.22;

  // ---------------------------------------------------------------- dusman
  static const double enemyWidth = 40;
  static const double enemyHeight = 40;
  static const double enemySpeedMin = 70;
  static const double enemySpeedMax = 140;

  // ---------------------------------------------------------------- spawn
  /// Dusmanlar bu aralikta rastgele gecikmelerle olusur (saniye).
  static const double spawnIntervalMin = 0.55;
  static const double spawnIntervalMax = 1.40;

  /// Zorluk egrisi: her [difficultyStepSeconds] saniyede spawn araligi
  /// [difficultyStepFactor] kadar kisalir, taban [spawnIntervalFloor]'dur.
  static const double difficultyStepSeconds = 15;
  static const double difficultyStepFactor = 0.88;
  static const double spawnIntervalFloor = 0.25;

  // ---------------------------------------------------------------- skor
  /// Hayatta kalinan her saniye icin puan.
  static const int scorePerSecond = 1;

  /// Vurulan her dusman icin puan.
  static const int scorePerEnemyKilled = 10;

  // ---------------------------------------------------------------- kalicilik
  /// Skor gecmisinde saklanacak en fazla kayit sayisi.
  static const int maxScoreHistoryEntries = 10;
}
