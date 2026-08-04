import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/presentation/providers/app_providers.dart';
import 'package:marsky_shooter/presentation/screens/game_screen.dart';

import '../helpers/in_memory_key_value_store.dart';

/// ANA MENUDE GERI TUSU DAVRANISININ REGRESYON TESTI.
///
/// GERCEK HATA: Onceden `PopScope(canPop: phase == menu)` yaziliydi ve ana
/// menude geri tusu OLU kaliyordu. Android 13+ ile geri hareketi
/// `onBackInvokedCallback` uzerinden yurur; `canPop` true oldugunda Flutter
/// istegi USTLENIR, kok rotada poplanacak bir sey bulamaz ve hicbir sey olmaz
/// -- sistem de kendi varsayilanini uygulamaz, cunku istek tuketilmistir.
/// Android 16 (SDK 36) emulatorunde release derlemesinde gorulup duzeltildi.
/// README "oynanis -> duraklat -> ana menu -> cikis" diyordu; son adim
/// calismiyordu.
///
/// NEDEN PLATFORM KANALI TAKLIT EDILIYOR: cikis `SystemNavigator.pop()` ile
/// yapilir ve bu bir platform kanali cagrisidir. Kanal dinlenmeden bu iddia
/// dogrulanamaz -- dogrulanmadigi icin de sessizce bozulmustu.
///
/// KAPSAM SINIRI: yalnizca ANA MENU durumu burada test edilir. Diger gecisler
/// (oynanis -> duraklat -> menu) oyun motoru seviyesinde `handleBackRequest()`
/// uzerinden `test/game/back_button_test.dart` icinde test edilir; oraya
/// varlik yuklemesi gerekmez. Bu ekran testinde oyunu baslatmak icin menu
/// overlay'ine dokunmak, dolayisiyla `GameWidget`in varlik yuklemesini
/// beklemek gerekirdi (bkz. `drag_input_test.dart` icindeki kilitlenme notu).
void main() {
  late List<String> systemCalls;

  setUp(() {
    systemCalls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall call,
        ) async {
          systemCalls.add(call.method);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('ana menude geri tusu uygulamadan cikar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore()),
        ],
        child: const MaterialApp(home: GameScreen()),
      ),
    );
    // `PopScope`, `GameWidget`in USTUNDE oldugu icin varlik yuklemesi bitmeden
    // de agactadir; oyun da ana menu fazinda baslar.
    await tester.pump();

    // Sistemin geri istegini, gercek platformun yaptigi gibi tetikler.
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(
      systemCalls,
      contains('SystemNavigator.pop'),
      reason:
          'ana menude geri tusu uygulamayi arka plana almali; '
          'yakalanan cagrilar: $systemCalls',
    );
  });
}
