# Mimari ve Karar Gerekçeleri

Bu doküman iki soruya cevap verir:
1. Case PDF'indeki her teknik beklenti **kodda nerede** karşılandı?
2. Alternatifler yerine **neden bu kararlar** verildi?

---

## 1. Katman Yapısı

```
lib/
├── main.dart                       → yalnızca bootstrap (yönlendirme, ProviderScope, ekran kilidi)
│
├── core/                           → paylaşılan sabitler; iş mantığı yok
│   ├── config/game_config.dart     → TÜM ayarlanabilir sayılar tek yerde
│   └── assets/game_assets.dart     → varlık adları (derleme zamanı güvenliği)
│
├── domain/                         → SAF DART — ne Flame ne Flutter import eder
│   ├── entities/score_entry.dart
│   └── repositories/score_repository.dart      (abstract interface class = sözleşme)
│
├── data/                           → domain sözleşmelerinin uygulamaları
│   ├── datasources/key_value_store.dart        (ince soyutlama, saf Dart)
│   ├── datasources/shared_prefs_key_value_store.dart
│   └── repositories/score_repository_impl.dart
│
├── game/                           → Flame dünyası; Riverpod'u ve UI'ı BİLMEZ
│   ├── marsky_game.dart            → kompozisyon kökü + durum geçişleri
│   ├── audio/                      → GameAudio sözleşmesi + Flame uygulaması + sessiz uygulama
│   ├── components/
│   │   ├── player/                 → PlayerComponent
│   │   ├── enemy/                  → EnemyComponent
│   │   ├── projectile/             → BulletComponent
│   │   └── background/             → parallax yıldız alanı
│   ├── input/drag_input_component.dart
│   ├── managers/
│   │   ├── enemy_spawner.dart      → rastgele spawn
│   │   └── difficulty_curve.dart   → SAF DART zorluk eğrisi
│   └── state/                      → GamePhase, GameScore, GameOverlays
│
└── presentation/                   → Flutter + Riverpod; oyunu barındırır
    ├── screens/game_screen.dart    → GameWidget + overlay kayıtları + ayar köprüsü
    ├── overlays/                   → ana menü, HUD, duraklat, oyun bitti
    └── providers/                  → Riverpod: yüksek skor, skor geçmişi, ses ayarı

tools/generate_assets.ps1           → tüm sprite ve sesleri ÜRETEN betik (3. parti telif yok)
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
| **Component mimarisi.** Oyun mantığı tek sınıfa yığılmamalı; oyuncu, düşman, arka plan ayrı sınıflar. | `lib/game/components/`, `lib/game/managers/`, `lib/game/input/` | `MarskyGame` bir **kompozisyon köküdür**: component'leri kurar, durum geçişini yönetir, davranış taşımaz. Hareket, ateş, spawn, zorluk, girdi, ses ve skor 10 ayrı sınıfta. |
| **Çarpışma: Flame'in yerleşik Hitbox'ları, performanslı.** Manuel matematiksel kesişim yasak. | `player_component.dart`, `enemy_component.dart`, `bullet_component.dart`, `marsky_game.dart` | `HasCollisionDetection` + `CircleHitbox`/`RectangleHitbox`. Elle yazılmış tek satır kesişim matematiği yok. Performans için `active`/`passive` ayrımı → düşmanlar birbirini taramaz. |
| **Durum yönetimi: Bloc/Riverpod/Provider.** Oyun dışı UI state'leri (ses ayarları, skor geçmişi). | `lib/presentation/providers/` | **Riverpod 3.4.2.** Üç provider: yüksek skor, skor geçmişi, ses ayarı — üçü de diskte kalıcı. Oyun **içi** skor ise `ValueNotifier`'da (gerekçe aşağıda). |
| **Asset yönetimi: preload, tekrarlı yükleme yok.** | `marsky_game.dart` (`onLoad`), `game_assets.dart` | `images.loadAll()` + `audio.preload()` oyun başında **bir kez**. Component'ler `images.fromCache(...)` ile önbellekten okur — hiçbir component `onLoad`'unda dosyadan yükleme yapmaz. |
| **Clean Architecture + SOLID, test edilebilir yapı.** | tüm ağaç + `test/` | Katmanlar yukarıda. `domain/` framework bağımsız. Bağımlılıklar constructor'dan enjekte edilir. **22 test** geçiyor. |

### Case PDF §2 — Oyun gereksinimleri

| Beklenti | Karşılık |
|---|---|
| Dokunarak/sürükleyerek kontrol | `DragInputComponent` — ekranın **her yerinden** sürükleme |
| Rastgele aralıkla spawn, oyuncuya doğru hareket | `EnemySpawner` + `EnemyComponent` (spawn anında oyuncuya doğru birim vektör) |
| Anlık güncellenen skor | `HudOverlay` + `ValueListenableBuilder` |
| Ana menü (başla + en yüksek skor) | `MainMenuOverlay` |
| Oyun içi | `GamePhase.playing` |
| Duraklat (tamamen durur, devam edilir) | `PauseOverlay` + `pauseEngine()`/`resumeEngine()` |
| Oyun bitti (son skor + yeniden başla) | `GameOverOverlay` |

---

## 3. Kritik Kararlar ve Gerekçeleri

### 3.1 Neden Riverpod (Bloc veya Provider değil)

| | Değerlendirme |
|---|---|
| **Provider** | Riverpod'un atası; aynı geliştirici eksiklerini gidermek için Riverpod'u yazdı. `BuildContext` bağımlılığı var, derleme zamanı tip güvenliği zayıf. **Hayır.** |
| **Bloc** | Doğru bir seçim ama bu ölçekte ağır: 3 küçük özellik için 3 Event + 3 State + 3 Bloc sınıfı. **Hayır.** |
| **Riverpod** | `BuildContext` gerektirmez, derleme zamanı tip güvenli, `ProviderScope(overrides:)` ile test override'ı tek satır, özellik başına ~5 satır. **Seçilen.** |

### 3.2 Neden oyun içi skor Riverpod'da DEĞİL

Skor saniyede onlarca kez değişir. Riverpod/Bloc üzerinden akıtılıp her değişimde widget ağacı
yeniden kurulsa kare hızı düşer. Bu yüzden:

- **Oyun içi state** (anlık skor) → `GameScore` içinde `ValueNotifier`, HUD'da
  `ValueListenableBuilder` ile **yalnızca skor metni** yeniden çizilir.
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

### 3.5 Neden varlıklar kod ile üretiliyor

`tools/generate_assets.ps1` tüm sprite ve sesleri üretir (GDI+ ile PNG, ham PCM ile WAV).
Gerekçe: (1) üçüncü parti telif/lisans sorunu oluşmaz, tüm varlıklar özgündür, (2) varlıklar
yeniden üretilebilir ve versiyonlanabilir, (3) inceleyen kişi görsellerin nereden geldiğini tek
dosyada görür. Yıldız alanı sabit tohumlu `Random` ile üretilir — her çalıştırmada aynı desen
çıkar, `git diff`'te sebepsiz değişiklik olmaz.

---

## 4. Geliştirme Sırasında Çıkan Gerçek Problemler

Bunlar tahminle değil, **ölçümle** bulundu ve çözümleri koda yorum olarak işlendi.

### 4.1 Hitbox'lar varsayılan olarak "içi boş"

**Belirti:** Mermi düşmanın tam merkezine geldiğinde isabet kaydedilmiyordu. Teşhis testi
gösterdi ki 3 hitbox kayıtlı, AABB'ler açıkça kesişiyor, çarpışma tipleri doğru — ama olay
tetiklenmiyor. Elle `collisionDetection.run()` çağırmak da işe yaramadı, yani sorun `update`
zincirinde değildi.

**Sebep:** Flame'in kesişim algoritmaları **kenar kesişimi** arar. Küçük mermi dikdörtgeni büyük
düşman dairesinin tamamen içine girdiğinde hiçbir kenar kesişmez ve kesişim kümesi boş döner
(`flame/src/geometry/shape_intersections.dart:85`).

**Çözüm:** Üç hitbox da `isSolid: true`. Bu, kapsanma durumunu da çarpışma sayar. Bu yalnızca
test kurgusu değildi — canlı oyunda da mermiler ıskalayacaktı.
Regresyon testi: `test/game/collision_test.dart` içinde mermi kasıtlı olarak düşmanın merkezine
konur.

### 4.2 Ses, oyunu test edilemez hale getiriyordu

**Belirti:** `flame_audio` arka planda `path_provider` platform kanalını kullanıyor; unit test
ortamında `MissingPluginException` atıp oyunun ayağa kalkmasını engelliyordu.

**Çözüm:** `GameAudio` sözleşmesi + `FlameGameAudio` (üretim) + `SilentGameAudio` (test).
Tek satırlık bir yama yerine soyutlama seçildi, çünkü aynı kapı PDF'in istediği **ses ayarı
(mute)** özelliğini de tek yerden çözüyor — `if (!muted)` kontrolü her `play` çağrısına
dağılmıyor.

### 4.3 Overlay kayıtları oyunu widget'a bağımlı kılıyordu

**Belirti:** Oyun `overlays.add('main_menu')` çağırıyor, ancak overlay widget'larını `GameWidget`
kaydediyor. Unit testte `GameWidget` olmadığı için Flame "Trying to add an unknown overlay"
assert'i atıyordu.

**Çözüm:** Test yardımcısı (`test/helpers/test_game.dart`) aynı kimlikleri boş builder'larla
`overlays.addEntry` ile kaydeder. Assert'i devre dışı bırakmak yerine testin üretim ortamını
taklit etmesi seçildi — yazım hatasına karşı güvenlik ağı korunur.

### 4.4 Puanın %88'i tek kaynaktan geliyordu

**Belirti:** Emülatörde gerçek bir oyun oynanıp oyun bitti ekranındaki skor dökümü okundu:
55 saniyede **60 düşman** öldürülmüş, yani +600 puan — skorun **%88'i**. Hayatta kalma (+55)
ve elmas (+25) gürültü seviyesindeydi.

**Kök neden (asıl mesele):** Bu bir puan ayarı sorunu değil, bir **oynanış** sorunuydu.
Düşmanlar oyuncuyu *kusursuz* nişanlıyordu; mermiler de oyuncudan düz yukarı çıktığı için her
düşman kendiliğinden mermi hattına giriyordu. Öldürmek beceri gerektirmiyordu.

**Çözüm iki katmanda:**
1. **Oynanış:** nişana ±20° rastgele sapma (`GameConfig.enemyAimSpread`). Düşmanlar açılı gelir,
   oyuncunun vurmak için yatayda hizalanması gerekir, bir kısmı kaçar. Hesap `EnemyAim` adında
   **saf bir fonksiyona** çıkarıldı — sapmanın hız büyüklüğünü bozmadığı ve en büyük sapmada bile
   düşmanın yukarı gitmediği oyun döngüsü çalıştırılmadan test edilir. (Açı üzerinden hesaplanır:
   vektöre doğrudan sapma eklenirse hem yön hem hız değişir.)
2. **Puan değerleri:** saniye +1→+10, elmas +25→+100 (düşman +10 sabit). Elmas en değerli, çünkü
   onu almak tek gerçek risk/ödül kararıdır.

**Yeniden ölçüm** (aynı yöntem, aynı ortam): 51 sn hayatta kalma +510 (%52), 27 düşman +270 (%28),
2 elmas +200 (%20). Öldürülen düşman sayısı 60'tan 27'ye indi ve oyun hâlâ ölümle sonuçlanıyor —
yani baskı korundu.

Not: bu sayılar tek bir dosyada (`GameConfig`) toplandığı için ayarlama üç satırlık bir
değişiklikti. Sihirli sayıları component'lerin içine dağıtmamanın somut kazancı budur.

---

## 5. Test Stratejisi

`flutter test` → **22 test**, `flutter analyze` → sıfır uyarı.

| Dosya | Kapsam |
|---|---|
| `test/domain/score_entry_test.dart` | JSON gidiş-dönüşü, değer bazlı eşitlik (saf Dart) |
| `test/game/difficulty_curve_test.dart` | Zorluk eğrisi: zamanla kısalma, taban değeri aşmama, min ≤ max |
| `test/game/game_score_test.dart` | Kesirli `dt` biriktirme, FPS'ten bağımsız puanlama, reset |
| `test/game/marsky_game_boot_test.dart` | `onLoad` component'leri bağlıyor mu, varlıklar önbellekte mi |
| `test/game/collision_test.dart` | Mermi→düşman, oyuncu→düşman, kapsanma regresyonu, sahne temizliği |
| `test/game/game_phase_test.dart` | Menüde ateş/spawn yok, duraklatmada skor durur, overlay senkronizasyonu |

Sıkı statik analiz: `strict-casts`, `strict-inference`, `strict-raw-types` + 10 ek lint kuralı
(`analysis_options.yaml`).

---

## 6. Bilinçli Olarak Kapsam Dışı

Case "karmaşık senaryolara gerek yoktur; temel mekaniklerin kusursuz çalışması beklenir" diyor.
Bu doğrultuda aşağıdakiler **kasıtlı olarak** yapılmadı:

- Can/kalkan sistemi (tek çarpışma = oyun bitti). `PlayerComponent` çarpışmayı yalnızca
  *bildirir*, kararı `MarskyGame` verir — can sistemi eklenmek istenirse oyuncu sınıfı değişmez.
- Farklı düşman türleri, güç yükseltmeleri, patlama animasyonu.
- Windows desktop hedefi: Visual Studio C++ araç zinciri gerektirdiği için kurulmadı.
  Hedef platform Android; geliştirme sırasında hızlı iterasyon için web (Chrome) kullanıldı.
