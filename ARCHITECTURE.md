# Mimari ve Karar Gerekçeleri

Bu doküman iki soruya cevap verir:
1. Case PDF'indeki her teknik beklenti **kodda nerede** karşılandı?
2. Alternatifler yerine **neden bu kararlar** verildi?

`lib/` 45 dosya / 3.511 satır · `test/` 27 dosya / 2.733 satır · **140 test** · satır kapsamı **%91** · `flutter analyze` sıfır uyarı

---

## 1. Katman Yapısı

```
lib/
├── main.dart                       → yalnızca bootstrap (ProviderScope, dikey mod kilidi)
├── app/marsky_app.dart             → MaterialApp kabuğu
│
├── core/                           → paylaşılan sabitler; iş mantığı yok
│   ├── config/game_config.dart     → TÜM ayarlanabilir sayılar + tutarlılık assert'leri
│   ├── assets/game_assets.dart     → varlık adları (derleme zamanı güvenliği)
│   └── diagnostics/frame_report.dart → kare süresi ölçümü (yalnızca profile derlemesi)
│
├── domain/                         → SAF DART — ne Flame ne Flutter import eder
│   ├── entities/score_entry.dart
│   ├── repositories/score_repository.dart      (abstract interface class = sözleşme)
│   └── repositories/settings_repository.dart   (ses ayarı sözleşmesi)
│
├── data/                           → domain sözleşmelerinin uygulamaları
│   ├── datasources/key_value_store.dart        (ince soyutlama, saf Dart)
│   ├── datasources/shared_prefs_key_value_store.dart
│   ├── datasources/storage_keys.dart           → disk anahtarları tek yerde
│   ├── repositories/score_repository_impl.dart
│   └── repositories/settings_repository_impl.dart
│
├── game/                           → Flame dünyası; Riverpod'u ve UI'ı BİLMEZ
│   ├── marsky_game.dart            → kompozisyon kökü + durum geçişleri + havuzlar
│   ├── audio/                      → GameAudio sözleşmesi + Flame uygulaması + sessiz uygulama
│   ├── components/
│   │   ├── player/                 → PlayerComponent (sürükleme takibi + otomatik ateş)
│   │   ├── enemy/                  → EnemyComponent
│   │   ├── projectile/             → BulletComponent
│   │   ├── pickup/                 → PickupComponent (toplanabilir elmas)
│   │   ├── effects/                → ExplosionComponent
│   │   ├── background/             → parallax yıldız alanı
│   │   └── play_area_bounds.dart   → ekran sınırı kontrolleri (extension)
│   ├── input/drag_input_component.dart
│   ├── managers/
│   │   ├── interval_spawner.dart   → ortak üretim iskeleti (Template Method)
│   │   ├── enemy_spawner.dart      → zorluk eğrisi + üst sınır
│   │   ├── pickup_spawner.dart     → sabit aralık
│   │   ├── difficulty_curve.dart   → SAF DART zorluk eğrisi
│   │   └── enemy_aim.dart          → SAF DART nişan/sapma hesabı
│   └── state/                      → GamePhase, GameScore, RunState, GameOverlays
│
└── presentation/                   → Flutter + Riverpod; oyunu barındırır
    ├── screens/game_screen.dart    → GameWidget + overlay kayıtları + geri tuşu + ayar köprüsü
    ├── screens/game_boot_views.dart→ yükleme ve hata ekranları
    ├── overlays/                   → ana menü, HUD, duraklat, oyun bitti (+ ortak widget'lar)
    └── providers/                  → Riverpod: yüksek skor, skor geçmişi, ses ayarı

tools/generate_assets.ps1           → sprite, ses ve launcher ikonlarını ÜRETEN betik
.github/workflows/ci.yml            → her push'ta format + analiz + test
```

**Bağımlılık yönü tek taraflıdır:**

```
presentation ──> game ──> core
     │                     ▲
     └────────> data ──────┘
                  │
                  ▼
               domain   (hiçbir şeye bağımlı değil)
```

`game/` katmanı Riverpod'u hiç bilmez. `domain/` katmanı hiçbir framework'ü bilmez. Bu, testlerde
oyun motorunu ve iş mantığını platform kanalı kurmadan çalıştırabilmemizin sebebidir.

---

## 2. Case PDF §3 — Madde Madde Eşleme

| PDF Beklentisi | Nerede | Nasıl |
|---|---|---|
| **Flame kullanılması zorunludur.** Standart Flutter widget'ları ile yapılan oyunlar reddedilir. | `lib/game/**` | Tüm oynanış `FlameGame` + Flame Component System içinde. Flutter widget'ları **yalnızca** `game.overlays` ile menü/HUD'da — bu Flame'in kendi önerdiği yol. Oynanışta tek bir `Positioned`/`AnimatedContainer` yok. |
| **Component mimarisi.** Oyun mantığı tek sınıfa yığılmamalı; oyuncu, düşman, arka plan ayrı sınıflar. | `lib/game/components/`, `managers/`, `input/` | `MarskyGame` bir **kompozisyon köküdür**: component'leri kurar, durum geçişini yönetir, davranış taşımaz. Hareket, ateş, spawn, zorluk, nişan, girdi, ses, skor ve efektler ayrı sınıflarda. |
| **Çarpışma: Flame'in yerleşik Hitbox'ları, performanslı.** Manuel matematiksel kesişim yasak. | `player/`, `enemy/`, `projectile/`, `pickup/`, `marsky_game.dart` | `HasCollisionDetection` + `CircleHitbox`/`RectangleHitbox`. Elle yazılmış tek satır kesişim matematiği yok. Performans için `active`/`passive` ayrımı → düşmanlar birbirini taramaz (§3.6). |
| **Durum yönetimi: Bloc/Riverpod/Provider.** Oyun dışı UI state'leri (ses ayarları, skor geçmişi). | `lib/presentation/providers/` | **Riverpod 3.4.2.** Üç provider: yüksek skor, skor geçmişi, ses ayarı — üçü de diskte kalıcı. Oyun **içi** skor ise `ValueNotifier`'da (§3.2). |
| **Asset yönetimi: preload, tekrarlı yükleme yok.** | `marsky_game.dart` (`onLoad`), `game_assets.dart` | `images.loadAll()` + `audio.preload()` oyun başında **bir kez**. Component'ler `images.fromCache(...)` ile önbellekten okur — hiçbir component `onLoad`'unda dosyadan yükleme yapmaz. |
| **Performanslı olması** | `marsky_game.dart`, `enemy_spawner.dart` | Üç yapısal karar: `active`/`passive` çarpışma ayrımı, **object pooling** (§3.5), eşzamanlı düşman üst sınırı (§3.7). Ayrıca ekran dışına çıkan her nesne ağaçtan çıkarılır. |
| **Clean Architecture + SOLID, test edilebilir yapı.** | tüm ağaç + `test/` | Katmanlar yukarıda. `domain/` framework bağımsız. Ses, rastgelelik ve depo constructor'dan enjekte edilir. Test stratejisi → §5. |

### Case PDF §2 — Oyun gereksinimleri

| Beklenti | Karşılık |
|---|---|
| Dokunarak/sürükleyerek kontrol | `DragInputComponent` — ekranın **her yerinden** sürükleme (§3.3) |
| Rastgele aralıkla spawn, oyuncuya doğru hareket | `EnemySpawner` + `EnemyAim` (spawn anında oyuncuya doğru, ±20° sapmalı) |
| Süreye **veya** toplanan nesneye bağlı skor | **Üçü birlikte:** hayatta kalma + vurulan düşman + toplanan elmas (`GameScore`). Elmas ayrıca **silahı yükseltir** (§3.11) |
| Anlık güncellenen skor | `HudOverlay` + `ValueListenableBuilder` — skor, kalan can ve silah seviyesi **ayrı ayrı** dinlenir, biri değişince diğerleri yeniden kurulmaz |
| Ana menü (başla + en yüksek skor) | `MainMenuOverlay` — ayrıca skor geçmişi ve kural özeti (`HowToPlay`) |
| Oyun içi | `GamePhase.playing` |
| Duraklat (tamamen durur, devam edilir) | `PauseOverlay` + `pauseEngine()`/`resumeEngine()` |
| Oyun bitti (son skor + yeniden başla) | `GameOverOverlay` — ayrıca skor kaynak dökümü ve rekor bildirimi |

---

## 3. Kritik Kararlar ve Gerekçeleri

### 3.1 Neden Riverpod (Bloc veya Provider değil)

| | Değerlendirme |
|---|---|
| **Provider** | Riverpod'un atası; aynı geliştirici eksiklerini gidermek için Riverpod'u yazdı. `BuildContext` bağımlılığı var, derleme zamanı tip güvenliği zayıf. **Hayır.** |
| **Bloc** | Doğru bir seçim ama bu ölçekte ağır: 3 küçük özellik için 3 Event + 3 State + 3 Bloc sınıfı. **Hayır.** |
| **Riverpod** | `BuildContext` gerektirmez, derleme zamanı tip güvenli, `ProviderScope(overrides:)` ile test override'ı tek satır, özellik başına ~5 satır. **Seçilen.** |

Riverpod'un test override'ı dekoratif değil: overlay widget testleri yalnızca **en alttaki disk
erişimini** taklit eder (`InMemoryKeyValueStore`), provider'lar ve repository gerçek kodla çalışır.

### 3.2 Neden oyun içi skor Riverpod'da DEĞİL

Skor saniyede onlarca kez değişir. Riverpod üzerinden akıtılıp her değişimde widget ağacı yeniden
kurulsa kare hızı düşer.

- **Oyun içi state** (anlık skor, oyun durumu) → `ValueNotifier`; HUD `ValueListenableBuilder` ile
  **yalnızca skor metnini** yeniden çizer.
- **Oyun dışı state** (yüksek skor, ses ayarı, skor geçmişi) → Riverpod, diskte kalıcı.

Bu ayrım PDF'in "oyun dışı UI state'leri için" ifadesinin birebir uygulamasıdır.

### 3.3 Neden sürükleme girdisi oyuncunun içinde değil

`DragCallbacks` yalnızca **kendi sınırları içinde başlayan** sürüklemeyi alır. Mixin doğrudan
`PlayerComponent`'e eklenseydi gemiyi hareket ettirmek için tam olarak geminin üstüne basmak
gerekirdi — mobilde parmak gemiyi kapatır. `DragInputComponent` `containsLocalPoint`'i her zaman
`true` döndürür, ekranın her yerinden sürükleme çalışır. Ayrıca girdi toplama sorumluluğu
oyuncudan ayrılmış olur: ileride klavye/jiroskop desteği eklenirse `PlayerComponent` değişmez.

### 3.4 Neden sabit çözünürlüklü kamera

`CameraComponent.withFixedResolution(480, 800)`. Aksi halde büyük ekranlı cihazda oyuncu daha
geniş bir alan görür ve oyun kolaylaşır — yani ekran boyutu adaleti bozar. Ayrıca
`viewfinder.anchor = topLeft` ile dünya koordinatları `(0,0)-(480,800)` olur; varsayılan merkez
hizalama `-240..240` aralığı üretir ve tüm konum hesaplarını sezgisellikten çıkarırdı.

### 3.5 Neden object pooling — ve neden Flame'in hazır havuzu

Mermi saniyede ~4,5, düşman ~1-4 kez üretiliyor; bir dakikalık oyunda ~400 nesne çöpe gidiyor.
Havuz, ekrandan çıkan nesneyi silmek yerine kenara koyar ve sonraki üretimde aynı nesneyi
yeniden kullanır.

**Kendi havuzumuz yazılmadı, Flame'in `ComponentPool`'u kullanıldı.** Flame'inki nesneyi otomatik
geri alır ve bunu **doğru sırayla** yapar: `component.mounted` tamamlanmasını bekler, *sonra*
`component.removed` dinler. Elle yazılan bir havuzda en sinsi hata tam buradadır —
`removeFromParent()` yaşam döngüsü kuyruğuna alındığı için nesne henüz sökülmemişken havuza
konursa yeniden `add` edilir ve "zaten mount edilmiş component" hatası oluşur.

Yeniden kullanımda `reset(...)` çağrılır; düşmanın `_isDying` bayrağının sıfırlanması kritiktir —
temizlenmezse geri dönüşen düşman "ölü" işaretli kalır ve mermiler ona isabet etmez.

`PickupComponent` **bilinçli olarak havuzlanmadı**: 3,5-7 saniyede bir üretiliyor, kazanç
ölçülemez seviyede kalır, karmaşıklık ise gerçek olur.

### 3.6 Çarpışma tipleri: neden bu dağılım

| Nesne | Tip | Tipik sayı |
|---|---|---|
| Oyuncu | `active` | 1 |
| Mermi | `active` | ~8 |
| Düşman | `passive` | ~10 |
| Elmas | `passive` | ~2 |

Flame yalnızca **en az biri `active` olan** çiftleri tarar. Bu dağılımda düşman-düşman çiftleri
**hiç taranmaz** — asıl kazanç budur.

**Alternatif değerlendirildi ve reddedildi:** düşmanları `active`, oyuncu+mermileri `passive`
yapmak. O durumda oyuncu-mermi çiftleri taranmazdı (küçük kazanç) ama düşman-düşman çiftleri
taranmaya başlardı (10 düşman = 45, 24 düşman = 276 gereksiz çift). Mevcut dağılım daha iyi.

### 3.7 Eşzamanlı düşman üst sınırı — savunma önlemi

Zorluk eğrisi spawn aralığını 0,25 saniyeye kadar indiriyor; düşman ekranda 6-11 saniye kalıyor.
Teorik olarak ~40 düşman birikebilir. **Ölçüm bunun pratikte gerçekleşmediğini gösterdi** (3
dakikalık simülasyonda zirve 9), çünkü oyuncu o kadar uzun yaşamıyor. Yine de sınır (24) eklendi:
3 dakika yaşayan usta bir oyuncu bu noktaya ulaşır ve sınırsız birikme hem kare hızını düşürür
hem kaçılacak boşluk bırakmaz. Sınıra ulaşıldığında spawn atlanır, sayaç normal işler.

### 3.8 Ölüm animasyonu penceresi

Çarpışma anında `pauseEngine()` çağrılsa patlama ve ekran sarsıntısı **hiç görünmez**; ekran birden
donar ve oyuncu neden öldüğünü anlamaz. Bu yüzden 0,55 saniyelik bir pencere var: motor çalışmaya
devam eder (efektler oynar) ama oynanış mantığı durur (`isPlaying` false → ateş, spawn ve skor
işlemez). Pencere `dt` biriktiren düz bir sayaçla yönetilir; Flame'in `TimerComponent`'i
kullanılmadı (§4.5).

### 3.9 Geri tuşu bir kademe yukarı çıkarır

`oynanış → duraklat → ana menü → uygulamadan çıkış`. Ele alınmazsa oyun ortasında geri tuşu
uygulamayı kapatır ve skor kaybolur. Duraklatmada geri = "devam et" yapılsaydı oyuncu
`oynanış ↔ duraklat` arasında sıkışır, geri tuşuyla uygulamadan hiç çıkamazdı. Kararı oyun verir
(`MarskyGame.handleBackRequest`), `PopScope` yalnızca olayı iletir.

### 3.10 Neden varlıklar kod ile üretiliyor

`tools/generate_assets.ps1` tüm sprite, ses ve launcher ikonlarını üretir (GDI+ ile PNG, ham PCM
ile WAV). Gerekçe: (1) üçüncü parti telif/lisans sorunu oluşmaz, (2) varlıklar yeniden üretilebilir
ve versiyonlanabilir, (3) inceleyen kişi görsellerin nereden geldiğini tek dosyada görür. Yıldız
alanı ve ikon sabit tohumlu `Random` ile üretilir — her çalıştırmada aynı desen çıkar, `git diff`'te
sebepsiz değişiklik olmaz. Launcher ikonu **oyunun gerçek oyuncu sprite'ından** üretilir, yani ikon
ile oyun içindeki gemi birebir aynıdır.

### 3.11 Güç ilerlemesi: neden bu üç mekanik birlikte

**Problem ölçümle bulundu.** Tek temasla ölünen sürümde gerçek oyunlar **11-26 saniye**
sürüyordu. Oyuncu bir elması toplayıp güçlendiğini fark etmeden oyun bitiyordu; zorluk artıyor
ama oyuncu hiç güçlenmiyordu, yani bir koşunun **arkı yoktu**: kaybetmek kaçınılmazdı ve
kazanılan hiçbir şey yoktu.

Üç mekanik ayrı ayrı değil **bir set olarak** eklendi, çünkü teker teker işe yaramazlar:

| Mekanik | Tek başına neden yetmez |
|---|---|
| **Elmas → silah seviyesi** | Koşu 15 saniye sürüyorsa oyuncu yükseltmenin tadını alamaz |
| **Üç can** | Güçlenme yoksa uzayan koşu yalnızca daha uzun bir kayıp olur |
| **Seviye duyurusu** | İlerleme göstergesi, ilerleyecek bir şey yoksa boş bir sayaçtır |

**Ölçülen sonuç:** aynı oynanış tarzıyla skorlar 260-460 bandından **740-1360** bandına
çıktı, yani koşular 2-3 kat uzadı.

**Sayı seçimlerinin gerekçeleri:**

- **Silah tavanı 4.** Daha yukarısı ya ekranı mermiyle doldurup çarpışma taramasını gereksiz
  büyütür ya da oyunu tamamen kolaylaştırır. Tavan olmasa "topla ve kazan" oyunu olurdu.
- **Son seviye mermi sayısını değil ateş hızını artırır.** Ekranda aynı anda bulunan mermi
  sayısı sınırlı kalsın diye; yükselme hissi hızdan gelir.
- **Mermi sapması 14 piksel.** Düşman hitbox yarıçapı 16,8; daha genişse iki mermi aynı
  düşmanı hiç vurmaz, daha darsa seviye atlama hissedilmez.
- **Vurulunca silah bir kademe düşer, 1'in altına inmez.** Ceza hissedilir olmalı ama oyuncuyu
  silahsız bırakmamalı; yoksa son can bir ceza değil mahkumiyet olur.
- **1,5 saniye dokunulmazlık.** Olmasa oyuncu bir düşman kümesine girdiğinde tüm canlarını
  tek anda kaybeder ve ne olduğunu anlamaz.
- **Seviye atlamasında 1 saniye üretim nefesi.** Zorluk artışı önceden **görünmüyordu**.

**İki incelik kayda değer:**

1. **Aynı karede iki düşman çarparsa tek can gider.** `startInvulnerability()`
   `handlePlayerHit` içinde **senkron** çağrıldığı için, o karede çalışan ikinci çarpışma geri
   çağrısı oyuncuyu zaten dokunulmaz görür. Dokunulmazlık kontrolünün çarpışma katmanında
   olmasının sebebi bu; `handlePlayerHit` içine konsa "hasar uygula" çağrısı kendi kendini
   sessizce yutan bir metoda dönüşürdü. Regresyon testi var.
2. **Nefes sırasında sayaçlar tamamen durur**, yalnızca `spawnOne()` atlanmaz. Atlansaydı geri
   sayım birikir ve nefes biter bitmez birkaç düşman aynı anda boşalırdı.

**`RunState` neden ayrı bir sınıf:** skor bir **sonuçtur**, can/silah/seviye ise oyunun anlık
**gücüdür**. `GameScore` içine konsalar "skor" adı yalancı olur ve oyun bitti ekranının
kopyaladığı döküm gereksizce büyürdü. `MarskyGame` içine alan olarak konsalar da kök sınıf üç
`ValueNotifier` daha taşıyıp davranış tutan bir sınıfa doğru kayardı. Ayrı durduğu için Flame'i
de Flutter'ı da bilmiyor ve tüm kuralları oyun ayağa kaldırılmadan test edilebiliyor.

---

## 4. Geliştirme Sırasında Çıkan Gerçek Problemler

Bunlar tahminle değil, **ölçümle** bulundu; çözümleri ve gerekçeleri koda yorum olarak işlendi.

### 4.1 Hitbox'lar varsayılan olarak "içi boş"

**Belirti:** Mermi düşmanın tam merkezine geldiğinde isabet kaydedilmiyordu. Teşhis testi gösterdi
ki 3 hitbox kayıtlı, AABB'ler açıkça kesişiyor, çarpışma tipleri doğru — ama olay tetiklenmiyor.
Elle `collisionDetection.run()` çağırmak da işe yaramadı, yani sorun `update` zincirinde değildi.

**Sebep:** Flame'in kesişim algoritmaları **kenar kesişimi** arar. Küçük mermi dikdörtgeni büyük
düşman dairesinin tamamen içine girdiğinde hiçbir kenar kesişmez ve kesişim kümesi boş döner
(`flame/src/geometry/shape_intersections.dart:85`).

**Çözüm:** Tüm hitbox'lar `isSolid: true` — kapsanma durumu da çarpışma sayılır. Bu yalnızca test
kurgusu değildi; canlı oyunda da mermiler ıskalayacaktı.
Regresyon testi: `test/game/collision_test.dart` mermiyi kasıtlı olarak düşmanın merkezine koyar.

### 4.2 Ses, oyunu test edilemez hale getiriyordu

**Belirti:** `flame_audio` arka planda `path_provider` platform kanalını kullanıyor; unit test
ortamında `MissingPluginException` atıp oyunun ayağa kalkmasını engelliyordu.

**Çözüm:** `GameAudio` sözleşmesi + `FlameGameAudio` (üretim) + `SilentGameAudio` (test). Tek
satırlık bir yama yerine soyutlama seçildi, çünkü aynı kapı PDF'in istediği **ses ayarı (mute)**
özelliğini de tek yerden çözüyor.

### 4.3 Oyun her sesle kullanıcının müziğini kesiyordu

**Belirti:** Emülatör logunda saniyede ~4,5 kez tekrarlayan satır:
`MediaFocusControl: abandonAudioFocus() ... callingPack=com.marsky.marsky_shooter`

**Sebep:** `audioplayers`'ın varsayılanı `AndroidAudioFocus.gain` — her ses için sistemden ses
odağı ister ve bırakır. Somut sonucu: oyuncu müzik dinliyorsa **her mermide müziği kesilir.**

**Çözüm:** `AndroidAudioFocus.none`. Ölçüm: odak isteği 4,5/sn → **0**, ses olayları 91 kez
çalmaya devam ediyor (yani efektler mevcut sesin üzerine biniyor).

### 4.4 Puanın %88'i tek kaynaktan geliyordu

**Belirti:** Emülatörde gerçek bir oyun oynanıp oyun bitti ekranındaki döküm okundu: 55 saniyede
**60 düşman** öldürülmüş, yani +600 puan — skorun **%88'i**. Hayatta kalma (+55) ve elmas (+25)
gürültü seviyesindeydi.

**Kök neden:** Bu bir puan ayarı sorunu değil, bir **oynanış** sorunuydu. Düşmanlar oyuncuyu
*kusursuz* nişanlıyordu; mermiler de oyuncudan düz yukarı çıktığı için her düşman kendiliğinden
mermi hattına giriyordu. Öldürmek beceri gerektirmiyordu.

**Çözüm iki katmanda:**
1. **Oynanış:** nişana ±20° rastgele sapma. Düşmanlar açılı gelir, oyuncunun vurmak için yatayda
   hizalanması gerekir, bir kısmı kaçar. Hesap `EnemyAim` adında **saf bir fonksiyona** çıkarıldı
   — sapmanın hız büyüklüğünü bozmadığı ve en büyük sapmada bile düşmanın yukarı gitmediği oyun
   döngüsü çalıştırılmadan test edilir. (Açı üzerinden hesaplanır: vektöre doğrudan sapma
   eklenirse hem yön hem hız değişir.)
2. **Puan değerleri:** saniye +1→+10, elmas +25→+100 (düşman +10 sabit).

**Yeniden ölçüm** (aynı yöntem, aynı ortam): 51 sn hayatta kalma +510 (%52), 27 düşman +270 (%28),
2 elmas +200 (%20). Öldürülen düşman 60'tan 27'ye indi ve oyun hâlâ ölümle sonuçlanıyor — baskı
korundu.

Bu ayar **üç satırlık** bir değişiklikti, çünkü tüm sayılar `GameConfig`'te toplanmıştı. Sihirli
sayıları component'lerin içine dağıtmamanın somut kazancı budur.

### 4.5 Asenkron `onLoad` senkron test döngüsünü kilitliyor

**Belirti:** Ölüm gecikmesi Flame'in `TimerComponent`'i ile yazıldı, 5 test kırıldı. Teşhis testi
timer'ın ağaca **hiç eklenmediğini** gösterdi.

**Sebep:** `TimerComponent`'in kendi `onLoad`'ı asenkrondur
(`flame/src/components/timer_component.dart:48`); mount edilmesi olay döngüsünün dönmesini
gerektirir. Testler kareleri senkron ilerlettiği için bu hiç olmaz.

**Çözüm:** `TimerComponent` bırakıldı, `dt` biriktiren düz bir sayaç kullanıldı — kodun geri
kalanıyla (ateş ve spawn sayaçları) tutarlı ve senkron olarak test edilebilir. Ayrıca component'
lerin `onLoad`'ları senkrona çevrildi: hitbox/efekt eklemek için beklemeye gerek yok ve asenkron
`onLoad` yaşam döngüsü kuyruğunda arkasındaki eklemeleri de bekletiyordu.

**Aynı sınıftan ikinci vaka:** havuz testi "geri dönüşüm çalışmıyor" dedi (86 farklı mermi / 90
atış). Flame'in havuzu nesneyi `component.removed` **Future**'ı tamamlanınca geri verir; senkron
döngüde Future'lar tamamlanmaz. Gerçek oyunda kareler arasında olay döngüsü döndüğü için havuz
çalışıyordu — **ölçüm hatalıydı.** Testler için `advanceAsync` yardımcısı eklendi.

### 4.6 Testler kırılgandı (flaky)

**Belirti:** Havuz eklendikten sonra "duraklatılmışken skor artmaz" testi kırıldı.

**Sebep:** Spawner'lar **tohumsuz `Random()`** kullanıyordu; duraklatma penceresinde şansa bağlı
bir mermi isabeti oluşuyordu. Havuz sadece zamanlamayı değiştirip şansı ters çevirdi.

**Çözüm:** (1) `MarskyGame` artık `Random` enjeksiyonu kabul ediyor, testler **sabit tohum**
kullanıyor. (2) Test toplam skora değil **hayatta kalma puanına** bakıyor — asıl iddia buydu;
`advance()` update'i elle çağırdığı için tesadüfi bir isabet hâlâ mümkündür ve bu test ortamının
yan etkisidir, gerçek oyunda duraklatıldığında `update` hiç çağrılmaz.

### 4.7 Widget testleri iki gerçek hata yakaladı

1. **Düzen taşması:** `StatRow` 6 haneli skorda 18 piksel taşıyordu — yüksek skora ulaşan oyuncu
   sarı-siyah taşma şeridi görecekti. Etiket `Expanded` içine alındı.
2. **Yanlış "YENİ REKOR":** Oyun bitti ekranı açıldığında yüksek skor diskten henüz okunmamış
   olabiliyor; `AsyncValue.value` null dönüyor, `previousBest = 0` sayılıyor ve **her skor rekor
   ilan ediliyordu.** Soğuk açılışta hemen ölen oyuncu tam bunu yaşar. Çözüm: anlık `.value`
   yerine `ref.read(highScoreProvider.future)` ile **yüklenmiş değeri beklemek**; okuma
   başarısızsa rekor iddiasında bulunulmaz.

### 4.8 Açılışta beyaz parlama

**Belirti:** Uygulama her açılışta beyaz bir ekranla başlıyordu (ölçüm: erken karelerde %94 beyaz).

**Sebep:** Flutter şablonunun varsayılanı `@android:color/white` ve `Theme.Light`.

**Çözüm:** Renk `colors.xml`'de tek yerde tanımlandı ve **dört yerde birden** uygulandı —
`launch_background.xml`, `drawable-v21` varyantı, `NormalTheme` pencere zemini ve `web/index.html`.
Biri atlanırsa parlama başka bir aşamada geri geliyordu. Ölçüm: %94 → **%0,1**.

### 4.9 `dispose` yarışı oyuncunun rekorunu siliyordu

**Belirti:** Yok — ve problem tam olarak buydu. Hata sessizdi.

**Sebep:** Skoru kalıcı kaydeden `_persistResult()`, yüksek skoru diskten okumak için
`await` ediyor, **sonra** `ref` üzerinden kayıt yapıyordu. Soğuk açılışta okuma birkaç on
milisaniye sürer; oyuncu o arada "TEKRAR DENE"ye basarsa overlay ağaçtan çıkar ve
`await` sonrası `ref` kullanımı Riverpod tarafından reddedilir. Çağrı `unawaited` olduğu
için fırlatılan hata **hiçbir yerde yakalanmıyordu**: ne çökme, ne log, ne uyarı — skor
sadece kaydolmuyordu.

**Nasıl bulundu:** Sahte depoya (`InMemoryKeyValueStore`) yapay okuma gecikmesi eklendi.
Sıfır gecikmeli sahte depo bu yarışı yapısal olarak gizliyordu; gecikme eklenince test ilk
denemede kırmızıya döndü ve `expected <10>, actual <null>` ile veri kaybını doğrudan gösterdi.

**Çözüm:** Tüm `ref` erişimleri ilk `await`ten **önce** yapılıyor. Notifier'lar
`ProviderContainer` içinde yaşadığı için (autoDispose değiller) referansları önden almak
yeterli: overlay yok olsa bile kayıt tamamlanır.

**Ders:** Sahte nesnenin gerçekten hızlı olması bir kolaylık değil, bir **kör noktadır**.
Asenkronluğu taklit etmeyen test double'ı, asenkron hataları da taklit etmez.

### 4.11 Ana menüde geri tuşu ölüydü

**Belirti:** README "oynanış → duraklat → ana menü → **çıkış**" diyordu. İlk üç adım
çalışıyordu, sonuncusu çalışmıyordu: ana menüde geri tuşu **hiçbir şey yapmıyordu.**

**Nasıl bulundu:** Release APK'sı Android 16 (SDK 36) emülatörüne kurulup elle her geçiş
denendi. `dumpsys activity activities` ile ölçüldü: geri tuşundan sonra `topResumedActivity`
hâlâ uygulamanın kendisiydi.

**Sebep:** `PopScope(canPop: phase == menu)`. Android 13+ ile geri hareketi
`onBackInvokedCallback` üzerinden yürür. `canPop` **true** olduğunda Flutter geri isteğini
**üstlenir**; kök rotada poplanacak bir şey bulamaz ve hiçbir şey yapmaz — sistem de kendi
varsayılanını uygulamaz, çünkü istek zaten tüketilmiştir. Yani `canPop: true` "sistem
halletsin" demek değil, "ben hallederim" demektir.

**Çözüm:** `canPop: false` — istek her zaman bize gelir, kararı zaten oyun veriyordu
(`handleBackRequest()` menüde `true` döner) ve çıkışı artık açıkça biz yapıyoruz:
`SystemNavigator.pop()`. Bu arada `canPop` sabitlendiği için faza bakan
`ValueListenableBuilder` gereksiz hâle geldi ve kaldırıldı — her faz geçişinde boşuna
yeniden kurulum yapıyordu.

**Regresyon testi:** `back_navigation_test.dart` platform kanalını taklit ederek
`SystemNavigator.pop` çağrısını yakalar. Eski koda geri dönülüp sınandı: yakalanan çağrı
listesi **boş** kalıyor, yani test gerçekten ayırt ediyor. Cihazda da doğrulandı: geri
tuşundan sonra ön plan launcher'a geçiyor, uygulama süreci ise yaşamaya devam ediyor
(temiz arka plan, çökme değil).

**Ders:** Bu hatayı hiçbir birim testi bulamazdı, çünkü hata **platform sözleşmesinde**ydi.
Release derlemesini gerçek bir cihazda elle çalıştırmanın yerini test tutmuyor.

### 4.12 Her ateş sesi yeni bir oynatıcı kuruyordu

**Belirti:** Release derlemesinde 30 saniyeden uzun oynandığında logcat'e yakalanmayan
hatalar düşüyordu:

```
Unhandled Exception: TimeoutException after 0:00:30.000000: Future not completed
  AudioPlayer._completePrepared (audioplayers/src/audioplayer.dart:372)
  AudioPlayer.setSourceAsset  (audioplayers/src/audioplayer.dart:429)
```

**Nasıl bulundu:** Ekran görüntüsü almak için oyun ~45 saniye kesintisiz oynandı. Daha kısa
oturumlarda hata hiç görünmüyordu, çünkü zaman aşımının dolması için 30 saniye geçmesi
gerekiyor.

**Sebep:** `FlameAudio.play` her çağrıda **yeni bir native oynatıcı** hazırlıyor. Ateş sesi
0,22 saniyede bir çalıyor, yani saniyede ~4,5 oynatıcı kurulup atılıyordu. Emülatörün ses
katmanı bu hızı karşılayamayınca bazı oynatıcılar "hazır" durumuna hiç gelmedi ve
`audioplayers`ın 30 saniyelik iç zaman aşımına takıldı.

**İkinci ve daha sinsi kusur:** Sonuç `await` edilmediği için hata **hiçbir yerde
yakalanmıyordu.** Beklenmeyen bir `Future`'ın hatası Flutter'ın zone yakalayıcısına düşer ve
loga "Unhandled Exception" olarak yazılır. Bu, §4.9'daki `dispose` yarışıyla **aynı hata
sınıfı**: beklememek, hatayı ele almak değildir.

**Çözüm:** Sık çalan sesler (ateş, patlama) `AudioPool` üzerinden çalıyor. Havuz önceden
hazırlanmış oynatıcıları yeniden kullanıyor; `audioplayers` dokümanı bunu tam olarak
"extremely quick firing, repetitive or simultaneous sounds" durumu için öneriyor. Elmas sesi
havuzlanmadı: 3,5-7 saniyede bir çalıyor, üst üste binmesi pratikte imkânsız. Ayrıca her
oynatma çağrısına açık bir hata yakalayıcı eklendi, böylece çalmayan bir ses artık logu
kirletmiyor.

**Doğrulama:** Aynı senaryo (45+ saniye kesintisiz oynanış) yeniden koşuldu:
**sıfır `TimeoutException`, sıfır yakalanmayan hata.**

**Ders:** Mermiler için nesne havuzu kullanıp ses oynatıcılarını her seferinde yeniden kurmak
tutarsızdı. Aynı problem (sık üretilen pahalı nesne) aynı çözümü istiyor; havuzun bir
katmanda doğru olması onu diğer katmanda hatırlamaya yetmiyor.

### 4.10 Gemi hareketi kare hızına göre farklı davranıyordu

**Belirti:** Kod yorumu "`dt` ile çarpıldığı için FPS'ten bağımsızdır" diyordu. Denetimde bu
iddia sınandı ve **yanlış çıktı.**

**Sebep:** Üstel yumuşatmanın yaygın yazımı `t = hız * dt`, gerçek çözümün yalnızca **birinci
mertebe yaklaşımıdır.** `hız = 18` ile 60 FPS'te `t = 0,30` çıkarken 20 FPS'te `t = 0,90`
oluyordu — yavaş cihazda gemi parmağa çok daha sert yapışıyor, yani **oynanış hissi cihaza
göre değişiyordu.** `dt` ile çarpmak tek başına FPS bağımsızlığı garanti etmez; yalnızca
doğrusal hareketlerde (mermi, düşman) yeterlidir.

**Ölçüm:** Aynı sürükleme, aynı süre (0,1 sn), iki kare hızı → **15,2 piksel** fark.

**Çözüm:** `t = 1 - exp(-hız * dt)`. Bu biçim tam olarak FPS bağımsızdır, çünkü
`(e^-0,3)^6 = (e^-0,9)^2 = e^-1,8` — kaç karede kat edildiği sonucu değiştirmez. `clamp(0,1)`
da gereksiz hâle gelir: sonuç doğal olarak `[0, 1)` aralığındadır, dolayısıyla kare
atlamasında hedefi aşma (overshoot) matematiksel olarak imkânsızdır.

**Regresyon testi:** `gameplay_behaviour_test.dart` aynı hareketi 60 ve 20 FPS'te koşup
sonuçların yarım pikselden az farkla eşleşmesini şart koşar. Test boş bir güvence değil:
eski formülle geri alınıp koşulduğunda **15,2 piksel farkla kırmızıya döndüğü doğrulandı.**

---

## 5. Test Stratejisi

`flutter test` → **140 test**, `flutter analyze` → sıfır uyarı, `dart format` → temiz.
Üçü de her push'ta CI'da kapı olarak koşar (`.github/workflows/ci.yml`).

Dört seviye:

**0. Mimari** (kaynak kodun kendisi denetlenir)

| Dosya | Kapsam |
|---|---|
| `architecture/layer_boundaries_test.dart` | Katman sınırları **makine tarafından** zorlanır: `domain/` framework import edemez, `game/` Riverpod'u ve `presentation/`i tanıyamaz, `data/` oyun motorunu tanıyamaz, `core/` üst katmanı tanıyamaz |

Bu seviyenin varlık sebebi: "Clean Architecture uyguladım" bir **iddiadır** ve katman ihlali
derleme hatası vermez — `domain/` içine `package:flutter` eklemek sorunsuz derlenir, yalnızca
mimari çürür. Doküman bunu tutamaz, test tutar. Kırmızı olduğunda hangi dosyanın hangi kuralı
ihlal ettiğini isim isim söyler.

**1. Saf mantık** (Flame/Flutter olmadan, düz unit test)

| Dosya | Kapsam |
|---|---|
| `domain/score_entry_test.dart` | JSON gidiş-dönüşü, değer bazlı eşitlik |
| `game/difficulty_curve_test.dart` | Zamanla kısalma, taban değeri aşmama, min ≤ max |
| `game/enemy_aim_test.dart` | Sapmasız tam nişan, hız büyüklüğünün korunması, açı kayması |
| `game/game_score_test.dart` | Kesirli `dt` biriktirme, FPS'ten bağımsız puanlama, reset |
| `game/score_breakdown_test.dart` | Kaynak dökümü ve toplamın tutarlılığı |
| `game/run_state_test.dart` | Can azalması ve sıfırın altına inmemesi, silah tavanı, vurulunca kademe düşmesi ama 1'in altına inmemesi, seviyenin süreden türetilmesi |

**2. Oyun davranışı** (`flame_test` ile oyun ayağa kaldırılıp kare kare ilerletilir)

| Dosya | Kapsam |
|---|---|
| `game/marsky_game_boot_test.dart` | `onLoad` component'leri bağlıyor mu, varlıklar önbellekte mi |
| `game/collision_test.dart` | Mermi→düşman, oyuncu→düşman, **kapsanma regresyonu**, sahne temizliği |
| `game/game_phase_test.dart` | Menüde ateş/spawn yok, duraklatmada skor durur, overlay senkronizasyonu |
| `game/gameplay_behaviour_test.dart` | Sürükleme, mermi yaşam döngüsü, spawner davranışı, **60/20 FPS'te aynı hareket** (§4.10) |
| `game/drag_input_test.dart` | Girdi yakalayıcı: sürüklemenin ekranın **her** noktasından kabul edilmesi, delta'nın dönüştürülmeden taşınması |
| `game/pickup_test.dart` | Toplama, çift sayım olmaması, ekran dışı temizlik, menüde üretim olmaması |
| `game/death_sequence_test.dart` | Patlama oluşumu ve kendini temizlemesi, ölüm penceresi, **kameranın başlangıca dönmesi** |
| `game/back_button_test.dart` | Kademeli geri: oynanış→duraklat→menü→çıkış |
| `game/component_pool_test.dart` | **Geri dönüşümün ölçülmesi**, üst sınır, `reset` bayrak temizliği |
| `game/enemy_cap_test.dart` | Sınır doluyken spawn atlanması, yan sınır temizliği, `GameConfig` tutarlılığı |
| `game/power_up_test.dart` | Elmasın hem puan hem güç vermesi, seviye 2'nin **gerçekten iki mermi** atması, **aynı karede iki temasın tek can götürmesi**, dokunulmazlığın bitmesi, seviye bannerı ve üretim nefesi |

**3. Sunum katmanı** (widget testleri, `ProviderScope(overrides:)` ile)

| Dosya | Kapsam |
|---|---|
| `presentation/main_menu_overlay_test.dart` | Kayıtlı skor gösterimi, kural özeti, BAŞLA'nın oyunu başlatması, geçmiş listesi |
| `presentation/hud_overlay_test.dart` | Skor metninin güncellenmesi, duraklat butonu |
| `presentation/pause_overlay_test.dart` | Anlık skor gösterimi ve canlı güncellenmesi, DEVAM ET, ANA MENÜ'nün skoru sıfırlaması, ses düğmesi |
| `presentation/main_menu_overlay_test.dart` | Kayıtlı skor, kural özeti metinleri (**can ve silah mekaniğini doğru anlattığı**), BAŞLA, geçmiş listesi |
| `presentation/game_over_overlay_test.dart` | Döküm, **diske yazma**, rekor bildirimi, düşük skorun rekoru ezmemesi, **`dispose` yarışında kaydın tamamlanması** (§4.9) |
| `presentation/back_navigation_test.dart` | Ana menüde geri tuşunun gerçekten çıkış yapması — platform kanalı taklit edilerek (§4.11) |
| `data/score_repository_impl_test.dart` | Repository mantığı (`mocktail` ile sahte depo) |

Testleri mümkün kılan şey **bağımlılık enjeksiyonu**: ses (`GameAudio`), rastgelelik (`Random`) ve
depo (`KeyValueStore`) dışarıdan verilir. Üçü de somut bir problemi çözer, dekoratif değildir.

Sıkı statik analiz: `strict-casts`, `strict-inference`, `strict-raw-types` + 10 ek lint kuralı.

### Ölçülen kapsam: %91 (801/880 satır)

```bash
flutter test --coverage
```

Rakamın kendisinden daha anlamlı olan, **kapsanmayan 79 satırın nerede olduğu.** Büyük kısmı
platform sınırındaki adaptörlerde:

| Dosya | Kapsam | Neden |
|---|---|---|
| `shared_prefs_key_value_store.dart` | **%0** (0/14) | Gerçek `shared_preferences` — platform kanalı gerektirir |
| `flame_game_audio.dart` | **%26** (7/27) | Gerçek `flame_audio` + oynatıcı havuzları — platform kanalı gerektirir |
| `game_boot_views.dart` | **%25** (3/12) | Yükleme ve hata ekranları; hata yolunu tetiklemek gerçek bir yükleme hatası ister |
| `game_audio.dart` | **%50** (4/8) | Sözleşme + `SilentGameAudio`; gerçek uygulamanın gövdesi yukarıda |
| `drag_input_component.dart` | **%50** (2/4) | `onDragUpdate` gövdesi, aşağıda |
| `settings_providers.dart` | **%50** (4/8) | Ses ayarı köprüsü; platform olayı ister |

İlk ikisi bir eksik değil, **tasarımın kendisi.** Platform sınırındaki ince adaptörler ve tam
olarak bu yüzden ayrı sınıflar: iş mantığı onların arkasındaki `GameAudio` / `KeyValueStore`
sözleşmelerine bağlı, dolayısıyla geri kalan her şey sahte uygulamalarla test edilebiliyor.
Dependency Inversion'ın somut karşılığı budur — **test edilemeyen kodu birkaç düzine satıra
sıkıştırmak.**

**Kapsam ölçümünün kendisi bir hata buldu:** `pause_overlay.dart` %0'daydı. Diğer üç
overlay'in widget testi vardı, duraklatmanın yoktu. Test **sayısına** bakıp "yeterli" demenin
neden yanlış olduğunun somut örneği; `pause_overlay_test.dart` bu boşluğu kapattı.

Kalan bilinen boşluk: `drag_input_component.dart`. `containsLocalPoint` ve delta'nın
dönüştürülmeden taşınması kapsandı; `onDragUpdate` gövdesi kapsanmadı — çünkü gerçek jest
boru hattı `GameWidget` içinde bir `GameRenderBox` istiyor ve `DisplacementEvent.localDelta`
yalnızca olay `deliverAtPoint` ile dağıtılırken okunabiliyor. Widget testiyle denendi ve
karşılıklı beklemeyle kilitlendi: varlık yüklemesi gerçek dosya okuması olduğu için
`tester.runAsync` gerekiyor, ama `game.loaded` kare çevrilmesini bekliyor ve `runAsync`
kare çevirmiyor. Doğru araç `integration_test` ile gerçek cihaz; yapılmadı ve gizlenmiyor.

> **Not:** Kapsam yüzdesinin paydası tamamen kararlı değil. Dart yalnızca test izolatının
> YÜKLEDIĞI kütüphaneleri raporlar, bu yüzden hangi dosyaların sayıldığı koşudan koşuya
> değişebilir. Yüzdeyi tek başına bir kalite kapısı olarak kullanmak bu nedenle yanıltıcı;
> burada onu bir **keşif aracı** olarak kullandım ve bir eksik test buldurdu.

### Yorum yazım kuralı

Kaynak dosyalardaki yorumlar **ASCII Türkçe** yazılır (`carpisma`, `bilincli`), iki istisna ile:

1. **Case PDF'inden birebir alıntılar** kaynağın kendi imlasıyla korunur — bir belgeyi
   alıntılarken metnini değiştirmek doğru olmaz.
2. **Kullanıcının gördüğü metinler** (`OYUN BİTTİ`, `EN YÜKSEK SKOR`) her zaman tam Türkçedir;
   arayüzde imla kısaltması yapılmaz.

Yani kod içinde iki yazım birlikte görünür ve bu bilinçlidir: ASCII olan geliştiriciye,
tam Türkçe olan ya kaynağa ya son kullanıcıya aittir.

---

## 6. Bilinçli Olarak Kapsam Dışı

Case "karmaşık senaryolara gerek yoktur; temel mekaniklerin kusursuz çalışması beklenir" diyor.
Bu doğrultuda aşağıdakiler **kasıtlı olarak** yapılmadı:

- **Farklı düşman türleri.** `EnemyComponent` türetilip `update`'i değiştirilerek eklenebilir;
  `MarskyGame` değişmez (açık/kapalı prensibi).
- **Elmas havuzlanması** — üretim sıklığı düşük, kazanç ölçülemez (§3.5).
- **Yerelleştirme (i18n)** — metinler kodda sabit Türkçe.
- **Windows desktop hedefi** — Visual Studio C++ araç zinciri gerektirdiği için kurulmadı. Hedef
  platform Android; geliştirme sırasında hızlı iterasyon için web (Chrome) kullanıldı.

> **Not:** Can sistemi ve silah yükseltmeleri ilk sürümde bu listedeydi. Sonradan eklendiler,
> çünkü ölçüm gerçek bir problemi gösterdi (koşular 11-26 saniyede bitiyordu — §3.11).
> Buradaki mimari öngörü işe yaradı: `PlayerComponent` çarpışmayı yalnızca *bildirdiği* ve
> kararı `MarskyGame` verdiği için, can sistemi eklenirken oyuncu sınıfında yalnızca
> dokunulmazlık kontrolü değişti.

---

## 7. Kare Süresi Ölçümü

`FrameReport` (`lib/core/diagnostics/frame_report.dart`) Flutter'ın `FrameTiming` verisini toplayıp
periyodik özet basar. **Yalnızca profil modunda** çalışır; `kProfileMode` derleme zamanında bilindiği
için release derlemesinde kodun tamamı elenir.

> `dumpsys gfxinfo` bu iş için kullanılamaz: o araç Android'in View sistemi (HWUI) karelerini sayar,
> Flutter ise kendi motoruyla çizip bu hattı büyük ölçüde atlar. Denendi ve
> `Failure while dumping the app` döndürdü.

**Ölçüm ortamı:** Pixel 7 emülatörü (API 36, WHPX), profil derlemesi, 1080×2400.
Her satır ~300 karelik (~5 sn) bir pencerenin özeti.

| Senaryo | p50 | p90 | Bütçeyi (16,67 ms) aşan |
|---|---|---|---|
| **Oynanış** (~10 düşman, ~8 mermi, çarpışma taraması) | 22,29 ms | 24,39 ms | %79–100 |
| **Ana menü** (yalnızca 2 parallax katmanı, oynanış yok) | 23,11 ms | 25,14 ms | %94–100 |

**Yorum:** Menü ile oynanış arasında **ölçülebilir fark yok** (22,3 ms vs 23,1 ms). Neredeyse boş
bir sahne de bütçeyi aştığı için ~22 ms'lik taban **emülatörün kendi maliyetidir**, oyunun yükü
değil. Bunun olumlu tarafı şudur: tam oynanış — 10 düşman, 8 mermi, aktif çarpışma taraması,
parallax ve nesne havuzu — boş bir menüye göre ek bir maliyet getirmiyor. Yani kare bütçesini
tüketen şey oyun mantığımız değil.

**Dürüstlük notu:** bu sayılar **60 FPS iddiasını desteklemez ve öyle bir iddia edilmiyor.**
Emülatör tabanı ~43 FPS'e karşılık geliyor. Gerçek kare hızı ancak **fiziksel bir cihazda**
ölçülebilir ve bu ölçüm yapılmadı. Aynı şekilde dokunma hissi de yalnızca emülatörde denendi.

---

## 8. Paket Boyutu

`flutter build apk --release --split-per-abi`

| Çıktı | Boyut |
|---|---|
| Tek paket (tüm ABI'ler) | 45,0 MB |
| `arm64-v8a` (güncel telefonlar) | **16,3 MB** |
| `armeabi-v7a` | 13,7 MB |
| `x86_64` (emülatör) | 17,7 MB |

Cihaz başına tek ABI indiği için gerçek kurulum boyutu ~16 MB. Teslimde ABI'ye ayrılmış paketler
verilir.
