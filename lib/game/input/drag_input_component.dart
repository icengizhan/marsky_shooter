import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// Ekranin tamamindan surukleme (drag) girdisi toplar ve deltayi disariya bildirir.
///
/// NEDEN AYRI BIR COMPONENT:
/// 1. `DragCallbacks` yalnizca KENDI sinirlari icinde BASLAYAN suruklemeyi alir.
///    Bu mixin dogrudan oyuncuya eklenseydi, oyuncuyu hareket ettirmek icin tam
///    olarak geminin uzerine basmak gerekirdi -- mobilde parmak gemiyi kapatir,
///    kotu bir deneyim olur. Burada [containsLocalPoint] her zaman `true` doner,
///    yani ekranin herhangi bir yerinden surukleme yeter.
/// 2. Girdi toplama sorumlulugu oyuncudan ayrilir. Oyuncu "nasil kontrol
///    edildigini" bilmez, sadece "ne kadar otelenecegini" bilir. Boylece ileride
///    klavye veya jiroskop destegi eklenirse oyuncu sinifi degismez.
///    (case PDF §3: "Tüm oyun mantığı tek bir sınıfa yığılmamalıdır")
///
/// DragCallbacks (Flame — src/events/callbacks/drag_callbacks.dart)
class DragInputComponent extends PositionComponent with DragCallbacks {
  DragInputComponent({required this.onPanDelta});

  /// Her surukleme adiminda olusan yer degistirme vektoru buraya bildirilir.
  final void Function(Vector2 delta) onPanDelta;

  /// Konum/boyut ne olursa olsun tum dokunuslari kabul et.
  /// Bu component gorunmezdir, yalnizca girdi yakalayicidir.
  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // localDelta: iki surukleme karesi arasindaki yer degistirme.
    // Mutlak konum yerine delta kullanmak, parmagin gemiye gore konumunu korur
    // (gemi parmagin altina "ziplamaz").
    onPanDelta(event.localDelta);
  }
}
