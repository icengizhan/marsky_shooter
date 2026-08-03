import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/domain/entities/score_entry.dart';

void main() {
  group('ScoreEntry', () {
    test('toJson -> fromJson gidis donusu degeri aynen korur', () {
      final ScoreEntry original = ScoreEntry(
        points: 1234,
        achievedAt: DateTime.utc(2026, 8, 3, 21, 30, 15),
      );

      final ScoreEntry restored = ScoreEntry.fromJson(original.toJson());

      expect(restored, original);
      expect(restored.points, 1234);
      expect(restored.achievedAt, DateTime.utc(2026, 8, 3, 21, 30, 15));
    });

    test('esitlik deger bazlidir, referans bazli degil', () {
      final DateTime when = DateTime.utc(2026, 8, 3);
      final ScoreEntry a = ScoreEntry(points: 10, achievedAt: when);
      final ScoreEntry b = ScoreEntry(points: 10, achievedAt: when);
      final ScoreEntry c = ScoreEntry(points: 11, achievedAt: when);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
