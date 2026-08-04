import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/game/input/drag_input_component.dart';

/// GIRDI YAKALAYICI TESTLERI.
///
/// NEDEN AYRI BIR DOSYA: diger oynanis testleri `player.nudge(...)` cagirarak
/// oyuncunun TEPKISINI sinar, ama girdi zincirini (jest -> Flame olay dagitimi
/// -> `DragInputComponent` -> `onPanDelta`) atlar. Kapsam olcumu bunu acikca
/// gosterdi: `drag_input_component.dart` %25'te kalmisti; sinifin asil karari
/// olan `containsLocalPoint` hic kosulmuyordu.
///
/// BILINCLI SINIR -- uctan uca jest testi BURADA YOK:
/// Gercek bir surukleme jestini surmek icin `GameWidget` icinde gercek bir
/// `GameRenderBox` gerekir; Flame'in olay dagitimi ona bagli. Ustelik
/// `DisplacementEvent.localDelta` yalnizca olay `deliverAtPoint` ile
/// dagitilirken okunabilir, yani elle olay uretmek de ise yaramaz.
/// Widget testinde denendi ve kilitlendi: varlik yuklemesi gercek dosya
/// okumasi oldugu icin `tester.runAsync` gerekiyor, ama `game.loaded` bir kare
/// cevrilmesini bekliyor ve `runAsync` kare cevirmiyor -- karsilikli bekleme.
///
/// Dogru arac bu degil, `integration_test` ile gercek cihazda kosmak.
/// Bu, bilinen ve kayitli bir kapsam bosluğudur (ARCHITECTURE.md §5).
void main() {
  group('Girdi yakalayici', () {
    test('ekranin HER noktasindan surukleme kabul eder', () {
      // Bu sinifin varlik sebebi tam olarak budur. `DragCallbacks` normalde
      // yalnizca component'in KENDI sinirlari icinde baslayan suruklemeyi alir;
      // mixin dogrudan oyuncuya eklenseydi gemiyi oynatmak icin tam geminin
      // uzerine basmak gerekirdi ve parmak gemiyi kapatirdi.
      final DragInputComponent input = DragInputComponent(
        onPanDelta: (Vector2 _) {},
      );

      expect(input.containsLocalPoint(Vector2.zero()), isTrue);
      expect(
        input.containsLocalPoint(Vector2(-9999, -9999)),
        isTrue,
        reason: 'sinirlarin cok disinda bir nokta bile kabul edilmeli',
      );
      expect(input.containsLocalPoint(Vector2(9999, 9999)), isTrue);
    });

    test('olusan delta oldugu gibi disariya bildirilir', () {
      // Girdi katmani deltayi DONUSTURMEZ, yalnizca tasir. Bir olceklendirme
      // veya ters cevirme buraya sizarsa kontrol hissi bozulur ve sebebini
      // oyuncu sinifinda aramak zaman kaybi olur.
      final List<Vector2> reported = <Vector2>[];
      final DragInputComponent input = DragInputComponent(
        onPanDelta: reported.add,
      );

      input.onPanDelta(Vector2(12, -34));

      expect(reported.single, Vector2(12, -34));
    });
  });
}
