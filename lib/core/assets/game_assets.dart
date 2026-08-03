/// Tum varlik (asset) adlari tek yerde toplanir.
///
/// Neden: dosya adlarini component'lerin icine string olarak yazmak, bir dosya
/// yeniden adlandirildiginda derleyicinin yakalamadigi CALISMA ANI hatasi
/// dogurur. Buradaki sabitleri kullanmak hatayi derleme zamanina tasir.
///
/// Yol onekleri yazilmaz: Flame goruntuleri `assets/images/`, sesleri
/// `assets/audio/` altinda arar (varsayilan prefix).
///
/// Bu dosyadaki varliklarin hepsi `tools/generate_assets.ps1` tarafindan
/// uretilmistir -- ucuncu parti telif icermez.
abstract final class GameAssets {
  // -------------------------------------------------------------- goruntuler
  static const String player = 'player.png';
  static const String enemy = 'enemy.png';
  static const String bullet = 'bullet.png';
  static const String pickup = 'pickup.png';

  /// Parallax icin dosenebilir (tileable) yildiz katmanlari.
  /// Uzak katman yavas, yakin katman hizli kayar -> derinlik hissi.
  static const String starsFar = 'stars_far.png';
  static const String starsNear = 'stars_near.png';

  /// `onLoad()` icinde TEK SEFERDE onbellege alinacak goruntuler.
  static const List<String> images = <String>[
    player,
    enemy,
    bullet,
    pickup,
    starsFar,
    starsNear,
  ];

  // -------------------------------------------------------------------- sesler
  static const String shootSound = 'shoot.wav';
  static const String explosionSound = 'explosion.wav';
  static const String pickupSound = 'pickup.wav';

  /// `onLoad()` icinde TEK SEFERDE onbellege alinacak sesler.
  static const List<String> audio = <String>[
    shootSound,
    explosionSound,
    pickupSound,
  ];
}
