import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// KATMAN SINIRLARINI KORUYAN TEST.
///
/// NEDEN BOYLE BIR TEST: "Clean Architecture uyguladim" bir iddiadir; iddiayi
/// yalnizca dokuman tutuyorsa ilk acele commit'te sessizce bozulur. Katman
/// ihlali derleme hatasi vermez -- `domain/` icine bir `package:flutter` import
/// eklemek sorunsuz derlenir, yalnizca mimari colur.
///
/// Bu test kaynak dosyalari OKUYUP import satirlarini denetler, boylece kural
/// CI'da makine tarafindan zorlanir. Kirmizi olursa mesaj hangi dosyanin hangi
/// kurali ihlal ettigini soyler.
///
/// Bagimlilik yonu (ARCHITECTURE.md §1):
///
///   presentation ──> game ──> core
///        │                     ▲
///        └────────> data ──────┘
///                     │
///                     ▼
///                  domain   (hicbir seye bagimli degil)
void main() {
  /// [directory] altindaki tum `.dart` dosyalarinin import satirlarini dondurur.
  List<({String file, String import})> importsUnder(String directory) {
    final Directory dir = Directory(directory);
    // Test cwd'si paket kokudur; degilse sessizce gecmek yerine yuksek sesle
    // basarisiz olmak isteriz.
    expect(
      dir.existsSync(),
      isTrue,
      reason: '$directory bulunamadi -- test paket kokunden kosmali',
    );

    final List<({String file, String import})> result =
        <({String file, String import})>[];
    for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      for (final String line in entity.readAsLinesSync()) {
        final String trimmed = line.trim();
        if (trimmed.startsWith('import ') || trimmed.startsWith('export ')) {
          result.add((file: entity.path, import: trimmed));
        }
        // Import'lar dosyanin basindadir; ilk siniftan sonra taramaya devam
        // etmek gereksiz.
        if (trimmed.startsWith('class ') || trimmed.startsWith('abstract ')) {
          break;
        }
      }
    }
    return result;
  }

  /// [directory] altinda [forbidden] parcalarindan hicbiri import edilmemeli.
  void expectNoImportsOf(
    String directory, {
    required List<String> forbidden,
    required String why,
  }) {
    final List<({String file, String import})> violations =
        importsUnder(directory).where((({String file, String import}) entry) {
          return forbidden.any(
            (String pattern) => entry.import.contains(pattern),
          );
        }).toList();

    expect(
      violations,
      isEmpty,
      reason:
          '$why\n'
          'Ihlaller:\n'
          '${violations.map((({String file, String import}) v) => '  ${v.file}: ${v.import}').join('\n')}',
    );
  }

  group('Katman sinirlari', () {
    test('domain/ SAF DART kalir -- hicbir framework import etmez', () {
      // Bu, Clean Architecture'in ve SOLID'in Dependency Inversion ilkesinin
      // somut kanitidir: is kurallari Flutter'a da Flame'e de bagli degildir,
      // bu yuzden `flutter_test` bile gerektirmeden test edilebilirler.
      // `dart:ui` de yasak: `Color`/`Offset` gibi tipler sizarsa katman artik
      // saf Dart olmaz.
      expectNoImportsOf(
        'lib/domain',
        forbidden: <String>['package:flame', 'package:flutter', 'dart:ui'],
        why:
            'domain/ katmani framework bagimsiz olmali. Bir varlik veya '
            'sozlesme Flutter tipine ihtiyac duyuyorsa tasarim yanlis: o tip '
            'presentation/ katmanina aittir.',
      );
    });

    test('domain/ kendi disindaki katmanlari import etmez', () {
      expectNoImportsOf(
        'lib/domain',
        forbidden: <String>['/data/', '/game/', '/presentation/', '/core/'],
        why:
            'domain/ bagimlilik grafiginin en dibindedir; yukari dogru '
            'hicbir bagimliligi olamaz.',
      );
    });

    test('game/ Riverpod ve UI katmanini BILMEZ', () {
      // Oyun motoru state yonetimi kutuphanesine baglanmazsa: (1) unit testte
      // ProviderScope kurmaya gerek kalmaz, (2) Riverpod degistirilse oyun kodu
      // hic degismez. Oyun ICI state `ValueNotifier` ile tasinir (§3.2).
      expectNoImportsOf(
        'lib/game',
        forbidden: <String>['riverpod', '/presentation/'],
        why:
            'game/ katmani Riverpod veya overlay widget\'larina bagimli olmamali. '
            'Oyun durumu disariya `ValueNotifier` ile duyurulur; kalicilik '
            'presentation/ katmaninda yapilir.',
      );
    });

    test('data/ oyun motorunu ve UI katmanini BILMEZ', () {
      expectNoImportsOf(
        'lib/data',
        forbidden: <String>['package:flame', '/game/', '/presentation/'],
        why:
            'data/ yalnizca domain sozlesmelerini uygular. Oyun motorunu '
            'tanimasi, depolama kodunu oyuna baglar ve ikisini birlikte '
            'test etmek zorunda kalirdik.',
      );
    });

    test('core/ hicbir ust katmani import etmez', () {
      // core/ en altta paylasilan sabit/arac katmanidir. Flutter'a bagimli
      // olmasi serbesttir (ornegin `FrameReport` `SchedulerBinding` kullanir),
      // ama kendisini kullanan katmanlari tanimamalidir.
      expectNoImportsOf(
        'lib/core',
        forbidden: <String>['/game/', '/presentation/', '/data/', '/domain/'],
        why:
            'core/ yaprak katmandir. Ust katmani import etmesi dongusel '
            'bagimlilik yaratir.',
      );
    });
  });
}
