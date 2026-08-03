/// Tek bir oyun sonucunu temsil eder.
///
/// DIKKAT: Bu dosya bilincli olarak SAF DART'tir -- ne `package:flame` ne de
/// `package:flutter` import eder. Clean Architecture'in domain katmani, dis
/// dunyadan (oyun motoru, UI, veritabani) bagimsiz olmalidir. Boylece bu sinif
/// Flutter test ortami kurmadan, duz `dart test` ile dogrulanabilir.
class ScoreEntry {
  const ScoreEntry({required this.points, required this.achievedAt});

  /// Kalici depodan okunan JSON'dan nesne uretir.
  factory ScoreEntry.fromJson(Map<String, dynamic> json) {
    return ScoreEntry(
      points: json[_pointsKey] as int,
      achievedAt: DateTime.parse(json[_achievedAtKey] as String),
    );
  }

  static const String _pointsKey = 'points';
  static const String _achievedAtKey = 'achievedAt';

  /// Oyun sonunda ulasilan skor.
  final int points;

  /// Skorun elde edildigi an.
  ///
  /// Disaridan verilir, icerde `DateTime.now()` cagrilmaz -- aksi halde bu sinif
  /// zamana bagli olur ve deterministik test edilemez.
  final DateTime achievedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    _pointsKey: points,
    _achievedAtKey: achievedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ScoreEntry &&
        other.points == points &&
        other.achievedAt == achievedAt;
  }

  @override
  int get hashCode => Object.hash(points, achievedAt);

  @override
  String toString() =>
      'ScoreEntry(points: $points, achievedAt: ${achievedAt.toIso8601String()})';
}
