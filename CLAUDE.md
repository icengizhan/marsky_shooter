# CLAUDE.md — marsky_shooter

MARSKY şirketi için Bilgisayar Mühendisi pozisyonu teknik değerlendirme case çalışması.
**Flutter + Flame ile 2D top-down shooter.**

> Bu dosya bu repoya özeldir. Başka projelerin (özellikle `Downloads/CLAUDE.md` içindeki
> WordPress eklenti projesinin) kuralları buraya **uygulanmaz**.

---

## Mevcut Durum (son güncelleme: 3 Ağustos 2026, 23:10)

> **ÖZET: Case gereksinimlerinin tamamı karşılandı.** 32 commit, 53 test geçiyor,
> `flutter analyze` sıfır uyarı, README + ARCHITECTURE.md yazıldı, release APK (45 MB)
> emülatörde doğrulandı. **Kalan tek zorunlu iş: 6 Ağustos'ta `okanaktas`'ı GitHub'da
> Collaborator olarak eklemek.**
>
> Zorunlu olmayan, istenirse yapılabilecekler: oynanış GIF'i (README'ye, en yüksek getirili),
> patlama animasyonu / ekran titremesi, overlay'ler için widget testleri.
>
> Emülatörde gerçek oyun oynanarak doğrulanan davranışlar: menü → oynanış → duraklat →
> oyun bitti geçişleri, kalıcı yüksek skor + skor geçmişi (uygulama yeniden açıldığında
> okunuyor), skor kırılımı, ses ayarı.

### Detaylı faz geçmişi

**Bitti:**
- **Faz 0** — Ortam: Flutter 3.44.8, Android SDK 36, AVD `marsky_pixel7`, `flutter doctor`
  Android/Chrome yeşil (Visual Studio bilinçli atlandı).
- **Faz 1** — Repo iskeleti, sıkı lint (`flutter analyze` temiz), `.gitattributes`,
  GitHub private repo `github.com/icengizhan/marsky_shooter` bağlı.
- **Faz 2** — Katmanlı mimari: `core/config/game_config.dart` (tüm sihirli sayılar),
  `domain/` (saf Dart: `ScoreEntry`, `ScoreRepository` sözleşmesi),
  `data/` (`KeyValueStore` arayüzü + `shared_preferences` uygulaması,
  `ScoreRepositoryImpl`), `game/marsky_game.dart` (boş uzay tuvali),
  `app/marsky_app.dart` (`GameWidget.controlled`). 2 test geçiyor, web derleniyor.

- **Faz 3** — Asset pipeline: `tools/generate_assets.ps1` ile ÖZGÜN sprite ve sesler
  üretiliyor (3. parti telif yok). `GameAssets` sabitleri + `onLoad()` içinde tek seferlik
  `images.loadAll()` / `audio.preload()`.
- **Faz 4** — Sabit çözünürlüklü kamera (480x800, viewfinder `topLeft`), parallax yıldız
  arka planı, `DragInputComponent` (ekranın her yerinden sürükleme), `PlayerComponent`
  (yumuşak takip + otomatik ateş), `BulletComponent`, `EnemyComponent` (oyuncuya doğru),
  `EnemySpawner` + `DifficultyCurve`, enjekte edilebilir `GameAudio`.
- **Faz 5** — Hitbox çarpışma (`active`/`passive` + `isSolid`), `GamePhase`, `GameScore`,
  `handlePlayerHit` / `togglePause` / `restart`. **16 test geçiyor.**

**Sıradaki:**
- **Faz 6** — 4 overlay (ana menü / HUD / pause / game over), `game.overlays` ile;
  `phase` ValueNotifier'ını dinleyecekler. Menü durumu şu an atlanmış — oyun doğrudan
  `playing` ile başlıyor, Faz 6 bunu düzeltecek.
- **Faz 7** — Riverpod provider'ları (yüksek skor, ses ayarı, skor geçmişi) +
  `ScoreRepositoryImpl` bağlantısı.
- **Faz 8** — Test kapsamını genişlet (spawner, drag input, repository + mocktail).
- **Faz 9** — README + ARCHITECTURE.md (PDF madde eşlemesi) + oynanış GIF + release APK.
- **Teslim günü (6 Ağu)** — `okanaktas` collaborator olarak eklenecek.

⚠️ Git CLI'dan push kimlik doğrulaması gerektiriyor. Bir kez kendi terminalinde
`git push origin main` çalıştırıp tarayıcıdan onaylandığında token saklanır ve
sonraki push'lar sorunsuz olur. O yapılmadıysa push'u GitHub Desktop üstlenir.

---

## Teslim Kısıtları (pazarlığa kapalı)

| Kısıt | Kaynak | Sonuç |
|---|---|---|
| **Teslim tarihi: 6 Ağustos 2026** | Mail | 3 Ağu / 4 Ağu / 5 Ağu akşamları + 6 Ağu sabahı tampon |
| Flame kullanımı **zorunlu** | Case PDF §3 | Oynanış `Positioned`/`AnimatedContainer` ile yapılırsa **doğrudan red** |
| Tek commit ile teslim = **elenme** | Case PDF §4 | Her adımda WIP commit. **Asla `squash`/`rebase` ile geçmiş ezilmez** |
| Repo **private** olacak | Case PDF §4 | Teslimde `okanaktas` collaborator olarak eklenir |

---

## Teknoloji Kararları ve Gerekçeleri

Bu bölüm `ARCHITECTURE.md`'ye de yansır — mülakatta savunulacak cevaplardır.

- **Tür: Top-down shooter.** PDF "Endless Runner veya Top-down Shooter" diyor, tür seçimi bize
  bırakılmış. Top-down seçildi çünkü: (1) PDF'in "oyuncuya doğru hareket eden düşmanlar" ifadesi
  birebir karşılanıyor, (2) sürükleme kontrolü doğal, (3) 3 ayrı çarpışma ilişkisi doğuyor →
  `active`/`passive` hitbox kararı gösterilebiliyor, (4) mermi havuzu (object pooling) somut bir
  performans argümanı sağlıyor.
- **State management: Riverpod 3.4.2.** Provider'ın modern hâli, `BuildContext` gerektirmez
  (oyun motorunun içinden de erişilebilir), derleme zamanı tip güvenli,
  `ProviderScope(overrides:)` ile test kolay. Bloc bu ölçekte gereksiz boilerplate.
  ⚠️ Riverpod **3.x** kullanılıyor — API'si 2.x dökümanlarından farklı, kod yazarken
  güncel dökümana bakılacak.
- **Geliştirme platformu: Windows desktop** (hızlı hot reload, akşam çalışması için kritik).
  **Doğrulama: Android emülatör** — her akşamın sonunda bir tur.
  **Ses testi yalnızca Android'de** — `flame_audio` Windows'ta güvenilir değil, oradaki
  sessizlik bug değildir.

---

## Mimari Kuralları (ihlal edilmez)

1. **`lib/domain/` katmanı `package:flame` ve `package:flutter` import ETMEZ.**
   Saf Dart. Bu, Clean Architecture'ın ve SOLID'in Dependency Inversion'ının kanıtı.
2. **Oyun mantığı tek sınıfa yığılmaz.** Oyuncu, düşman, mermi, arka plan, spawn yöneticisi
   ayrı `Component` sınıfları.
3. **Flutter widget'ları yalnızca overlay'lerde** (`game.overlays`): menü, HUD, pause,
   game over. Oynanışta asla.
4. **Çarpışma yalnızca Flame hitbox'ları ile.** Manuel `if (x1 < x2 + w2 && ...)` kesişim
   matematiği yasak — PDF açıkça bunu yasaklıyor.
   ⚠️ **Her hitbox `isSolid: true` olmalı.** Flame'in varsayılanı `false` ve şekli "içi boş
   halka" gibi ele alır: çarpışma yalnızca **kenarlar kesiştiğinde** bulunur. Küçük mermi
   hitbox'ı düşman dairesinin tamamen içine girdiğinde hiçbir kenar kesişmez ve **isabet
   sessizce kaybolur**. `isSolid` kapsanma durumunu da çarpışma sayar
   (bkz. `flame/src/geometry/shape_intersections.dart:85`). Bu, canlı olarak yaşandı ve
   `test/game/collision_test.dart` içinde regresyon testi var — o testi silme.
5. **Çarpışma tipleri:** hareket eden/isabet arayan taraf `active`, yalnızca vurulan taraf
   `passive`. Düşmanlar `passive` — birbirlerini kontrol etmezler, aksi halde N düşman için
   her karede ~N²/2 gereksiz çift taranır.
5. **`update(dt)` içinde hareket her zaman `dt` ile çarpılır.** Aksi hâlde oyun cihazın
   FPS'ine göre farklı hızda çalışır.
6. **Asset'ler yalnızca bir kez yüklenir** — `MarskyGame.onLoad()` içinde `images.loadAll()` /
   `FlameAudio.audioCache.loadAll()`. Component'ler cache'ten okur
   (`Sprite(images.fromCache(...))`), asla dosyadan.
7. **Oyun içi state Flame'de** (`ValueNotifier`), **oyun dışı state Riverpod'da.**
   Skor her karede Riverpod'a yazılmaz — oyun kasar. Yalnızca oyun bitince kalıcı kayda gider.

---

## Ortam

```
Flutter SDK : C:\Users\LENOVO\dev\flutter        (stable 3.44.8, Dart 3.12.2)
Proje       : C:\Users\LENOVO\Projects\marsky_shooter
Git         : C:\Program Files\Git\cmd\git.exe
```

⚠️ **Yeni shell'de PATH eski olabilir.** Komut öncesi tazele:
```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
```

⚠️ **Proje yolunda boşluk veya ASCII-dışı karakter olmamalı** — Flutter build'i kırılır.
Paket adı `marsky_shooter` (tire kullanılamaz, Dart kuralı).

### Komutlar

```powershell
flutter run -d windows          # hızlı iterasyon
flutter run -d emulator-5554    # Android doğrulama
flutter analyze                 # lint (commit öncesi temiz olmalı)
flutter test                    # testler
flutter build apk --release     # teslim APK'sı
```

---

## Çalışma Kuralları

- **Flame API'si için:** hafızadan yazma. `docs.flame-engine.org` veya pub.dev'deki güncel
  API'yi doğrula. Flame 1.38 `CameraComponent` + `World` ayrımını kullanır, eski
  `viewport`/`camera` API'si değişti.
- **Flutter/Dart core fonksiyonları için:** `api.flutter.dev` bağlantısı ekle.
- Fonksiyon/sınıf adının yanına `(Flame — [docs link])`, `(Flutter SDK — [docs link])` veya
  `(marsky_shooter — özel)` etiketi koy. Zaten var olan bir şeyi sıfırdan yazmayı önlemek için.
- **Her faz sonunda commit.** Mesaj formatı: Conventional Commits
  (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`).
- `flutter analyze` temiz olmadan commit atılmaz.
- **Commit yazarlığı: yalnızca repo sahibi.** Commit mesajlarına `Co-Authored-By` satırı
  veya herhangi bir AI/asistan atfı **eklenmez**. Author ve committer her zaman
  `icengizhan <ilaydacengizhann@gmail.com>` olur. Bu, teslim edilen bir değerlendirme
  çalışması olduğu için kesin kuraldır.
