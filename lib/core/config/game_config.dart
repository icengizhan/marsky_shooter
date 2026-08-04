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

  /// Dusmanin nisan sapmasi (radyan, +/-). ~20 derece.
  ///
  /// NEDEN SIFIR DEGIL: sapma olmadan her dusman oyuncuyu KUSURSUZ nisanlar.
  /// Mermiler de oyuncudan duz yukari cikitigi icin her dusman kendiliginden
  /// mermi hattina girer -- oldurmek beceri gerektirmez, bedava olur.
  /// Gercek oynanis olcumu bunu dogruladi: 55 saniyede 60 dusman oldu ve skorun
  /// %88'i buradan geldi.
  ///
  /// Sapma ile dusmanlar acili gelir: oyuncunun vurmak icin yatayda hizalanmasi
  /// gerekir ve bir kismi kacar. Hem nisan almak hem kacinmak beceri olur.
  static const double enemyAimSpread = 0.35;

  // ------------------------------------------------------- toplanabilir nesne
  static const double pickupWidth = 32;
  static const double pickupHeight = 32;

  /// Dusmanlardan yavas iner: oyuncuya yetisme sansi verir.
  static const double pickupSpeed = 85;

  /// Kendi ekseninde donme hizi (radyan/saniye). Yalnizca gorsel canlilik --
  /// daire hitbox donmeden etkilenmedigi icin oynanisi degistirmez.
  static const double pickupRotationSpeed = 1.4;

  /// Toplanabilir nesne olusma araligi (saniye).
  /// Zorluk egrisine BAGLI DEGIL: bu bir odul, ceza degil. Zamanla siklasirsa
  /// oyun kolaylasir, tam tersi olurdu.
  static const double pickupIntervalMin = 3.5;
  static const double pickupIntervalMax = 7.0;

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
  // Puan degerleri gercek oynanis olcumuyle dengelendi.
  //
  // Ilk degerler (1 / 10 / 25) ile olculen 55 saniyelik bir oyunda skorun
  // %88'i dusman oldurmekten geliyordu (60 dusman = 600 puan; hayatta kalma
  // yalnizca 55, elmas 25). Sebep tasarimin dogal sonucu: dusmanlar oyuncuya
  // dogru geldigi, mermiler de oyuncudan duz yukari cikti icin her dusman
  // kendiliginden mermi hattina giriyor -- oldurmek neredeyse bedava.
  //
  // Yeni degerlerle ayni oyun: hayatta kalma 550, dusman 550, elmas 300.
  // Uc kaynak da anlamli agirlikta.

  /// Hayatta kalinan her saniye icin puan.
  static const int scorePerSecond = 10;

  /// Vurulan her dusman icin puan.
  static const int scorePerEnemyKilled = 10;

  /// Toplanan her nesne icin puan. En degerli kaynak, cunku elmasi almak icin
  /// oyuncunun guvenli konumundan sapip dusmanlarin arasina girmesi gerekir --
  /// tek gercek risk/odul kararidir.
  static const int scorePerPickupCollected = 100;

  // ------------------------------------------------------- gorsel geri bildirim
  /// Patlama efektinin suresi (saniye).
  static const double explosionDuration = 0.32;

  /// Patlamanin buyume carpani (1.0 = buyumez).
  static const double explosionScaleTarget = 2.6;

  static const double enemyExplosionRadius = 15;
  static const double playerExplosionRadius = 26;
  static const double pickupFlashRadius = 13;

  /// Patlamalar SICAK renk (ates) tonundadir, nesnenin kendi rengi degil.
  /// Dusman macenta oldugu icin macenta bir patlama "buyumus dusman" gibi
  /// gorunur ve isabet okunmaz; turuncu hem koyu zeminde hem macenta sprite
  /// uzerinde net ayirt edilir.
  static const Color enemyExplosionColor = Color(0xFFFF9A4D);
  static const Color playerExplosionColor = Color(0xFFFFC46E);
  static const Color pickupFlashColor = Color(0xFFFFE58A);

  /// Olum aninda kameranin sapma miktari (piksel).
  static const double screenShakeOffset = 7;

  /// Bir sarsinti adiminin suresi. `alternate` ile ileri-geri gidildigi icin
  /// kamera baslangic konumuna geri doner, kalici kayma olusmaz.
  static const double screenShakeStepDuration = 0.045;
  static const int screenShakeRepeatCount = 3;

  /// Oyuncu oldukten sonra "oyun bitti" ekrani gelene kadar gecen sure.
  ///
  /// Bu pencere olmadan `pauseEngine()` aninda cagrildigi icin patlama hic
  /// gorunmez ve oyuncu neden oldugunu anlamaz.
  static const double deathAnimationDuration = 0.55;

  // ---------------------------------------------------------------- kalicilik
  /// Skor gecmisinde saklanacak en fazla kayit sayisi.
  static const int maxScoreHistoryEntries = 10;
}
