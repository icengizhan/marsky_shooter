import 'dart:convert';

import '../../core/config/game_config.dart';
import '../../domain/entities/score_entry.dart';
import '../../domain/repositories/score_repository.dart';
import '../datasources/key_value_store.dart';

/// [ScoreRepository] sozlesmesinin anahtar-deger deposu uzerindeki uygulamasi.
///
/// Depolama teknolojisini bilmez -- yalnizca [KeyValueStore] arayuzunu bilir.
/// Bu sayede testte sahte bir depo verilerek gercek bir cihaz/eklenti olmadan
/// dogrulanabilir.
class ScoreRepositoryImpl implements ScoreRepository {
  ScoreRepositoryImpl(this._store);

  /// Anahtarlar `marsky.` ile onekli: ayni cihazdaki baska uygulama
  /// verileriyle ve ileride eklenecek ayar anahtarlariyla cakismasin.
  static const String highScoreKey = 'marsky.high_score';
  static const String historyKey = 'marsky.score_history';

  final KeyValueStore _store;

  @override
  Future<int> readHighScore() async {
    final int? stored = await _store.readInt(highScoreKey);
    return stored ?? 0;
  }

  @override
  Future<bool> writeHighScoreIfHigher(int points) async {
    final int current = await readHighScore();
    if (points <= current) {
      return false;
    }
    await _store.writeInt(highScoreKey, points);
    return true;
  }

  @override
  Future<List<ScoreEntry>> readHistory() async {
    final String? raw = await _store.readString(historyKey);
    if (raw == null || raw.isEmpty) {
      return const <ScoreEntry>[];
    }
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic item) => ScoreEntry.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<void> appendToHistory(ScoreEntry entry) async {
    final List<ScoreEntry> history = await readHistory();

    // En yeni kayit basa eklenir, liste sabit uzunlukta tutulur. Aksi halde
    // her oyunda buyuyen ve hic temizlenmeyen bir veri birikir.
    final List<ScoreEntry> updated = <ScoreEntry>[entry, ...history]
        .take(GameConfig.maxScoreHistoryEntries)
        .toList(growable: false);

    final String encoded = jsonEncode(
      updated.map((ScoreEntry item) => item.toJson()).toList(growable: false),
    );
    await _store.writeString(historyKey, encoded);
  }
}
