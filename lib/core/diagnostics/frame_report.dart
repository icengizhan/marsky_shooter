import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Kare suresi olcumu (yalnizca PROFIL modunda).
///
/// NEDEN VAR: "performansli" bir oyun iddiasi ancak olculebilirse anlam tasir.
/// Bu sinif Flutter'in kendi kare zamanlamalarini toplayip periyodik bir ozet
/// basar; ortalamalar ve yuzdelikler logcat'ten okunabilir.
///
/// NEDEN `dumpsys gfxinfo` KULLANILMIYOR: o arac Android'in View sistemi
/// (HWUI) karelerini sayar. Flutter kendi motoruyla cizer ve bu hatti buyuk
/// olcude atlar; `gfxinfo` bu uygulama icin "Failure while dumping the app"
/// dondurur. Dogru kaynak Flutter'in `FrameTiming` verisidir.
///
/// NEDEN YALNIZCA PROFIL MODU:
///   - debug modunda kare sureleri anlamsizdir (JIT, assert'ler, denetimler),
///   - release'de olcum kodunun kendisi bile istenmez.
/// `kProfileMode` sabiti derleme zamaninda bilindigi icin release derlemesinde
/// bu kodun tamami elenir.
///
/// SchedulerBinding.addTimingsCallback
/// (Flutter SDK — https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addTimingsCallback.html)
abstract final class FrameReport {
  /// 60 Hz'de bir karenin butcesi (mikrosaniye).
  static const int _budgetMicros = 16667;

  /// Kac karede bir ozet basilacak (~5 saniye).
  static const int _reportEvery = 300;

  static final List<int> _frameMicros = <int>[];

  /// Olcumu baslatir. Profil modunda degilse hicbir sey yapmaz.
  static void startIfProfileMode() {
    if (!kProfileMode) {
      return;
    }
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    debugPrint('[FrameReport] olcum basladi (profil modu)');
  }

  static void _onTimings(List<FrameTiming> timings) {
    for (final FrameTiming timing in timings) {
      _frameMicros.add(timing.totalSpan.inMicroseconds);
    }
    if (_frameMicros.length < _reportEvery) {
      return;
    }
    _emitReport();
    _frameMicros.clear();
  }

  static void _emitReport() {
    final List<int> sorted = List<int>.of(_frameMicros)..sort();
    final int count = sorted.length;
    final int total = sorted.fold(0, (int sum, int v) => sum + v);
    final int janky = sorted.where((int v) => v > _budgetMicros).length;

    String ms(int micros) => (micros / 1000).toStringAsFixed(2);
    int percentile(double p) => sorted[((count - 1) * p).round()];

    debugPrint(
      '[FrameReport] kare=$count '
      'ort=${ms(total ~/ count)}ms '
      'p50=${ms(percentile(0.50))}ms '
      'p90=${ms(percentile(0.90))}ms '
      'p99=${ms(percentile(0.99))}ms '
      'enkotu=${ms(sorted.last)}ms '
      'butce_asan=$janky/$count '
      '(${(100 * janky / count).toStringAsFixed(1)}%)',
    );
  }
}
