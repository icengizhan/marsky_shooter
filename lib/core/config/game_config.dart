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

  // ------------------------------------------------------- guc yukseltmeleri
  /// Silah seviyesi tavani. Her elmas bir kademe yukseltir.
  ///
  /// 4'te durduruluyor: daha yukarisi ya ekrani mermiyle doldurup carpisma
  /// taramasini gereksiz buyutur ya da oyunu tamamen kolaylastirir. Tavan
  /// olmasa "topla ve kazan" oyunu olurdu.
  static const int maxWeaponLevel = 4;

  /// Seviye 2 ve 3'te mermilerin merkezden yatay sapmasi (piksel).
  ///
  /// 14 secildi: dusman hitbox yaricapi 16,8; daha genis olsa iki mermi ayni
  /// dusmani hic vurmaz, daha dar olsa seviye atlama hissedilmez.
  static const double bulletSpreadOffset = 14;

  /// Son seviyede ates araligi bu carpanla kisalir (0,8 = %25 daha hizli).
  ///
  /// Seviye 4 mermi SAYISINI artirmiyor, HIZINI artiriyor -- ekranda ayni anda
  /// bulunan mermi sayisi kontrol altinda kalsin diye.
  static const double maxLevelFireRateFactor = 0.8;

  // -------------------------------------------------------------------- can
  /// Oyuncunun vurus hakki.
  ///
  /// NEDEN 3, NEDEN 1 DEGIL: tek temasla oyun bitince olculen ortalama kosu
  /// 11-26 saniyede kaliyordu. Oyuncu silah yukseltmesini toplayip tadini
  /// almadan oyun bitiyor, yani guclenme dongusu hic kurulmuyordu.
  static const int playerMaxLives = 3;

  /// Vurus sonrasi dokunulmazlik suresi (saniye).
  ///
  /// Olmasa oyuncu bir dusman kumesinin icinde tum canlarini tek anda kaybeder
  /// ve ne oldugunu anlamaz. Bu pencerede gemi yanip soner.
  static const double invulnerabilityDuration = 1.5;

  /// Dokunulmazlikta gemi saniyede kac kez yanip soner.
  static const double invulnerabilityBlinksPerSecond = 6;

  // ---------------------------------------------------------------- seviye
  /// "SEVIYE N" yazisinin ekranda kalma suresi (saniye).
  static const double levelBannerDuration = 1.2;

  /// Seviye atlandiginda dusman uretiminin duraklama suresi (saniye).
  ///
  /// Kucuk bir nefes: oyuncu seviye atladigini fark eder ve yeni tempoya
  /// hazirlanir. Bu olmadan zorluk artisi gorunmez bir sekilde oluyordu.
  static const double levelUpSpawnPause = 1.0;

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

  /// Ekranda ayni anda bulunabilecek en fazla dusman sayisi.
  ///
  /// NEDEN GEREKLI: zorluk egrisi spawn araligini 0,25 saniyeye kadar indiriyor
  /// ve dusman ekranda 6-11 saniye kaliyor. Ust sinir olmadan cok uzun bir
  /// oyunda teorik olarak ~40 dusman birikebilir; bu hem kare hizini dusurur
  /// hem oyunu adaletsiz kilar (kacilacak bosluk kalmaz). Sinira ulasildiginda
  /// spawn ATLANIR, sayac normal isler.
  static const int maxConcurrentEnemies = 24;

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

  // ------------------------------------------------------------- havuz (pool)
  /// Havuzda tutulacak en fazla mermi/dusman sayisi.
  ///
  /// Ust sinir olmadan havuz, oyunun gordugu EN YOGUN ana gore buyur ve o
  /// bellegi bir daha geri vermez. Degerler ekranda ayni anda bulunabilecek
  /// nesne sayisinin biraz uzerinde tutuldu: mermi ekrani ~1,5 saniyede gecer
  /// ve saniyede ~4,5 atilir (~7 canli), dusman ~6-11 saniye yasar.
  static const int bulletPoolMaxSize = 32;
  static const int enemyPoolMaxSize = 48;

  // ---------------------------------------------------------------- kalicilik
  /// Skor gecmisinde saklanacak en fazla kayit sayisi.
  static const int maxScoreHistoryEntries = 10;

  // --------------------------------------------------------------- dogrulama
  /// Yapilandirmanin tutarli oldugunu dogrular.
  ///
  /// NEDEN: bu dosyadaki sayilar oyun dengesini ayarlarken elle degistiriliyor.
  /// `min` degerini `max`in uzerine cikarmak gibi bir yanlislik SESSIZ bir
  /// bozulma yaratir -- `randomBetween(min, max)` negatif aralikla calisir ve
  /// dusmanlar hic olusmaz. Buradaki kontroller boyle bir hatayi ilk karede,
  /// anlasilir bir mesajla yakalar.
  ///
  /// `assert` icinde cagrilir, yani YALNIZCA debug/test derlemesinde calisir;
  /// release performansina etkisi yoktur. Kullanimi:
  /// `assert(GameConfig.isConsistent);`
  static bool get isConsistent {
    assert(
      spawnIntervalMin <= spawnIntervalMax,
      'spawnIntervalMin, spawnIntervalMax degerini asamaz',
    );
    assert(
      spawnIntervalFloor <= spawnIntervalMin,
      'spawnIntervalFloor, spawnIntervalMin degerinden buyuk olamaz '
      '(taban zaten baslangic araliginin altinda olmali)',
    );
    assert(
      enemySpeedMin <= enemySpeedMax,
      'enemySpeedMin, enemySpeedMax degerini asamaz',
    );
    assert(
      pickupIntervalMin <= pickupIntervalMax,
      'pickupIntervalMin, pickupIntervalMax degerini asamaz',
    );
    assert(
      difficultyStepFactor > 0 && difficultyStepFactor < 1,
      'difficultyStepFactor 0 ile 1 arasinda olmali; 1 ve uzeri zorlugu '
      'AZALTIR, 0 ve alti araligi sifirlar',
    );
    assert(
      difficultyStepSeconds > 0,
      'difficultyStepSeconds sifir olamaz (sifira bolme)',
    );
    assert(fireCooldown > 0, 'fireCooldown sifir olamaz (sonsuz ates)');
    assert(
      maxConcurrentEnemies > 0,
      'maxConcurrentEnemies sifir olsa hic dusman olusmaz',
    );
    assert(
      playerEdgePadding * 2 < designWidth,
      'playerEdgePadding oyun alanindan genis olamaz',
    );
    assert(
      deathAnimationDuration > 0,
      'deathAnimationDuration sifir olsa olum animasyonu gorunmez',
    );
    assert(playerMaxLives > 0, 'playerMaxLives sifir olsa oyun hic baslamaz');
    assert(
      maxWeaponLevel >= 1,
      'maxWeaponLevel en az 1 olmali; 0 silahsiz oyuncu demek',
    );
    assert(
      maxLevelFireRateFactor > 0 && maxLevelFireRateFactor <= 1,
      'maxLevelFireRateFactor 0-1 arasinda olmali; 1 ustu son seviyeyi '
      'YAVASLATIR, 0 ise sonsuz ates',
    );
    assert(
      invulnerabilityDuration > 0,
      'invulnerabilityDuration sifir olsa oyuncu tum canlarini tek anda kaybeder',
    );
    assert(
      bulletSpreadOffset > 0,
      'bulletSpreadOffset sifir olsa coklu mermi ust uste biner',
    );
    assert(
      levelUpSpawnPause < difficultyStepSeconds,
      'levelUpSpawnPause zorluk adimindan uzun olsa spawn hic calismaz',
    );
    return true;
  }
}
