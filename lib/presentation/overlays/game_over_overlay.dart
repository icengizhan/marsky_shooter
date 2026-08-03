import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/score_entry.dart';
import '../../game/marsky_game.dart';
import '../providers/score_providers.dart';
import 'widgets/overlay_panel.dart';

/// Oyun bitti ekrani.
/// (case PDF §2.B: "Oyun Bitti: Çarpışma sonrası çıkan, son skoru gösteren ve
/// yeniden başlama seçeneği sunan ekran")
///
/// KALICI KAYIT BURADA YAPILIR, OYUN MOTORUNDA DEGIL: oyun sinifi Riverpod'u
/// veya `shared_preferences`i hic bilmez. Bu overlay gorundugu anda skoru
/// gonderir. Boylece kalicilik tamamen sunum katmaninda kalir ve oyun motoru
/// test edilirken disk/eklenti bagimliligi olusmaz.
class GameOverOverlay extends ConsumerStatefulWidget {
  const GameOverOverlay({required this.game, super.key});

  final MarskyGame game;

  @override
  ConsumerState<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends ConsumerState<GameOverOverlay> {
  /// Skor, overlay acilir acilmaz kopyalanir. `restart()` sonrasi oyunun skoru
  /// sifirlanacagi icin dogrudan okumaya guvenilemez.
  late final int _finalScore;

  bool _isNewRecord = false;

  @override
  void initState() {
    super.initState();
    _finalScore = widget.game.score.points.value;
    // Sonuc beklenmez: UI aninda cizilir, kayit arka planda tamamlanir.
    unawaited(_persistResult());
  }

  Future<void> _persistResult() async {
    // Rekor kontrolu GONDERMEDEN ONCE yapilir; gonderdikten sonra bakilirsa
    // yeni skor zaten rekor olmus olur ve karsilastirma anlamsizlasir.
    final int previousBest = ref.read(highScoreProvider).value ?? 0;
    final bool isRecord = _finalScore > previousBest;

    await ref.read(highScoreProvider.notifier).submit(_finalScore);
    await ref.read(scoreHistoryProvider.notifier).append(
      ScoreEntry(points: _finalScore, achievedAt: DateTime.now()),
    );

    // `mounted` kontrolu: oyuncu kayit tamamlanmadan "tekrar dene"ye basmis
    // olabilir; o durumda widget artik agacta degildir.
    if (mounted && isRecord) {
      setState(() => _isNewRecord = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<int> highScore = ref.watch(highScoreProvider);

    return OverlayPanel(
      title: 'OYUN BİTTİ',
      subtitle: _isNewRecord ? 'YENİ REKOR' : null,
      children: <Widget>[
        StatRow(label: 'SKOR', value: '$_finalScore'),
        StatRow(
          label: 'EN YÜKSEK SKOR',
          value: highScore.when(
            data: (int value) => '$value',
            loading: () => '—',
            error: (Object _, StackTrace _) => '—',
          ),
        ),
        const SizedBox(height: 20),
        MenuButton(label: 'TEKRAR DENE', onPressed: widget.game.startGame),
        const SizedBox(height: 10),
        MenuButton(
          label: 'ANA MENÜ',
          isPrimary: false,
          onPressed: widget.game.goToMenu,
        ),
      ],
    );
  }
}
