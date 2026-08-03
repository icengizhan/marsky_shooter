# CLAUDE.md — marsky_shooter

MARSKY şirketi için Bilgisayar Mühendisi pozisyonu teknik değerlendirme case çalışması.
**Flutter + Flame ile 2D top-down shooter.**

> Bu dosya bu repoya özeldir. Başka projelerin (özellikle `Downloads/CLAUDE.md` içindeki
> WordPress eklenti projesinin) kuralları buraya **uygulanmaz**.

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
