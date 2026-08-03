import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/score_entry.dart';
import '../../domain/repositories/score_repository.dart';
import 'app_providers.dart';

/// En yuksek skor (kalici).
///
/// NEDEN RIVERPOD BURADA, FLAME DEGIL: bu deger oyun DISI bir state'tir --
/// ana menu gosterir, game over ekrani guncellenir, uygulama yeniden acildiginda
/// diskten okunur. Oyun icindeki anlik skor ise `GameScore` icinde
/// `ValueNotifier` olarak tutulur, cunku saniyede onlarca kez degisir ve
/// Riverpod uzerinden akitilirsa gereksiz widget yeniden kurulumu olusur.
///
/// `AsyncNotifier`: baslangic degeri diskten OKUNDUGU icin asenkron. UI
/// yuklenirken `AsyncValue.loading` durumunu gorur, cokmez.
class HighScoreNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() => ref.watch(scoreRepositoryProvider).readHighScore();

  /// Oyun sonundaki skoru gonderir. Rekor kirilmadiysa hicbir sey yazilmaz.
  Future<void> submit(int points) async {
    final ScoreRepository repository = ref.read(scoreRepositoryProvider);
    final bool improved = await repository.writeHighScoreIfHigher(points);
    if (improved) {
      state = AsyncValue<int>.data(points);
    }
  }
}

final AsyncNotifierProvider<HighScoreNotifier, int> highScoreProvider =
    AsyncNotifierProvider<HighScoreNotifier, int>(HighScoreNotifier.new);

/// Son oyunlarin skor gecmisi (kalici, en yeniden en eskiye).
class ScoreHistoryNotifier extends AsyncNotifier<List<ScoreEntry>> {
  @override
  Future<List<ScoreEntry>> build() =>
      ref.watch(scoreRepositoryProvider).readHistory();

  Future<void> append(ScoreEntry entry) async {
    final ScoreRepository repository = ref.read(scoreRepositoryProvider);
    await repository.appendToHistory(entry);
    state = AsyncValue<List<ScoreEntry>>.data(await repository.readHistory());
  }
}

final AsyncNotifierProvider<ScoreHistoryNotifier, List<ScoreEntry>>
scoreHistoryProvider =
    AsyncNotifierProvider<ScoreHistoryNotifier, List<ScoreEntry>>(
      ScoreHistoryNotifier.new,
    );
