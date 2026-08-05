import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/core/config/game_config.dart';
import 'package:marsky_shooter/game/state/run_state.dart';

/// KOSU DURUMU TESTLERI (saf mantik, oyun ayaga kaldirilmadan).
///
/// `RunState` bilincli olarak Flame'i de Flutter widget'ini de bilmiyor, bu
/// yuzden can/silah/seviye kurallari tum oyun dongusu simule edilmeden
/// dogrulanabiliyor. Ayni mantik `MarskyGame` icine gomulu olsa her kural icin
/// oyunu ayaga kaldirmak gerekirdi.
void main() {
  late RunState run;

  setUp(() => run = RunState());
  tearDown(() => run.dispose());

  group('Can', () {
    test('yapilandirmadaki can sayisiyla baslar', () {
      expect(run.lives.value, GameConfig.playerMaxLives);
      expect(run.isAlive, isTrue);
    });

    test('her vurus bir can dusurur, sifirda hayatta degil', () {
      for (int i = GameConfig.playerMaxLives; i > 0; i--) {
        expect(run.lives.value, i);
        run.takeHit();
      }
      expect(run.lives.value, 0);
      expect(run.isAlive, isFalse);
    });

    test('can sifirin ALTINA inmez', () {
      // Olum penceresinde fazladan bir carpisma gelirse negatife dusmemeli;
      // HUD negatif can cizmeye calisirdi.
      for (int i = 0; i < GameConfig.playerMaxLives + 3; i++) {
        run.takeHit();
      }
      expect(run.lives.value, 0);
    });
  });

  group('Silah seviyesi', () {
    test('1. seviyede tek mermi atar', () {
      expect(run.weaponLevel.value, 1);
      expect(run.bulletsPerShot, 1);
    });

    test('elmas topladikca mermi sayisi artar', () {
      run.upgradeWeapon();
      expect(run.bulletsPerShot, 2);
      run.upgradeWeapon();
      expect(run.bulletsPerShot, 3);
    });

    test('TAVANA ulasinca daha fazla yukselmez', () {
      for (int i = 0; i < GameConfig.maxWeaponLevel + 5; i++) {
        run.upgradeWeapon();
      }
      expect(run.weaponLevel.value, GameConfig.maxWeaponLevel);
      expect(run.isWeaponMaxed, isTrue);
    });

    test('tavandayken upgradeWeapon false doner', () {
      while (!run.isWeaponMaxed) {
        expect(run.upgradeWeapon(), isTrue);
      }
      expect(
        run.upgradeWeapon(),
        isFalse,
        reason: 'cagiran taraf ses/efekt oynatmamak icin bunu bilmeli',
      );
    });

    test('son seviye mermi SAYISINI degil ates HIZINI artirir', () {
      // Bilincli tasarim: mermi sayisi 3'te sabit kalir, ekran mermiyle dolup
      // carpisma taramasi gereksiz buyumesin.
      while (!run.isWeaponMaxed) {
        run.upgradeWeapon();
      }
      expect(run.bulletsPerShot, 3);
      expect(run.fireCooldown, lessThan(GameConfig.fireCooldown));
    });

    test('vurus alinca silah bir kademe DUSER', () {
      run.upgradeWeapon();
      run.upgradeWeapon();
      expect(run.weaponLevel.value, 3);

      run.takeHit();

      expect(run.weaponLevel.value, 2, reason: 'ceza hissedilir olmali');
    });

    test('silah seviyesi 1in ALTINA dusmez', () {
      // Son can bir ceza olmali, mahkumiyet olmamali: oyuncu silahsiz kalmaz.
      run.takeHit();
      run.takeHit();
      expect(run.weaponLevel.value, 1);
      expect(run.bulletsPerShot, 1);
    });
  });

  group('Zorluk seviyesi', () {
    test('1. seviyede baslar', () {
      expect(run.level.value, 1);
    });

    test('zorluk adimi gectikce seviye atlar ve true doner', () {
      expect(run.syncLevel(0), isFalse, reason: 'basta atlama yok');
      expect(
        run.syncLevel(GameConfig.difficultyStepSeconds + 0.1),
        isTrue,
        reason: 'ilk adim gecildi',
      );
      expect(run.level.value, 2);
    });

    test('ayni seviye icinde tekrar tekrar sorulunca false doner', () {
      run.syncLevel(GameConfig.difficultyStepSeconds + 0.1);
      expect(
        run.syncLevel(GameConfig.difficultyStepSeconds + 0.2),
        isFalse,
        reason: 'banner her karede yeniden tetiklenmemeli',
      );
    });

    test('seviye gecen sureden TURETILIR, sayacla degil', () {
      // Tek hamlede uc adim atlanirsa seviye de uce cikar. Ayri bir sayac
      // kullanilsa gosterge ile gercek zorluk birbirinden ayrilabilirdi.
      run.syncLevel(GameConfig.difficultyStepSeconds * 3 + 0.1);
      expect(run.level.value, 4);
    });
  });

  test('reset her seyi baslangica dondurur', () {
    run.upgradeWeapon();
    run.takeHit();
    run.syncLevel(GameConfig.difficultyStepSeconds * 2);

    run.reset();

    expect(run.lives.value, GameConfig.playerMaxLives);
    expect(run.weaponLevel.value, 1);
    expect(run.level.value, 1);
  });
}
