import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/game_config.dart';
import '../../domain/entities/score_entry.dart';
import '../../game/marsky_game.dart';
import '../../game/state/game_score.dart';
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
///
/// Skor DOKUMU de burada gosterilir: oyuncu puanin nereden geldigini,
/// ogrenmeye en meraklı oldugu anda gorur.
class GameOverOverlay extends ConsumerStatefulWidget {
  const GameOverOverlay({required this.game, super.key});

  final MarskyGame game;

  @override
  ConsumerState<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends ConsumerState<GameOverOverlay> {
  /// Sonuc, overlay acilir acilmaz KOPYALANIR. `startGame()` sonrasi oyunun
  /// sayaclari sifirlanacagi icin canli degere guvenilemez.
  late final ScoreBreakdown _result;

  bool _isNewRecord = false;

  @override
  void initState() {
    super.initState();
    _result = widget.game.score.breakdown;
    // Sonuc beklenmez: UI aninda cizilir, kayit arka planda tamamlanir.
    unawaited(_persistResult());
  }

  Future<void> _persistResult() async {
    // Rekor kontrolu GONDERMEDEN ONCE yapilir; gonderdikten sonra bakilirsa
    // yeni skor zaten rekor olmus olur ve karsilastirma anlamsizlasir.
    //
    // `.future` ile YUKLENMIS deger BEKLENIR, anlik `.value` okunmaz:
    // yuksek skor diskten asenkron gelir. Bu ekran acildiginda okuma henuz
    // bitmemis olabilir; o durumda `.value` null doner, `previousBest` 0
    // sayilir ve HER SKOR yanlislikla "YENI REKOR" ilan edilir. Soguk acilista
    // oyuncu hemen olurse tam olarak bu yasanir. Widget testi bu hatayi
    // yakaladi (test/presentation/game_over_overlay_test.dart).
    int previousBest;
    try {
      previousBest = await ref.read(highScoreProvider.future);
    } on Object {
      // Okuma basarisiz olduysa rekor iddiasinda bulunmayiz.
      previousBest = _result.total;
    }
    final bool isRecord = _result.total > previousBest;

    await ref.read(highScoreProvider.notifier).submit(_result.total);
    await ref
        .read(scoreHistoryProvider.notifier)
        .append(ScoreEntry(points: _result.total, achievedAt: DateTime.now()));

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
        StatRow(label: 'SKOR', value: '${_result.total}'),
        StatRow(
          label: 'EN YÜKSEK SKOR',
          value: highScore.when(
            data: (int value) => '$value',
            loading: () => '—',
            error: (Object _, StackTrace _) => '—',
          ),
        ),
        const Divider(color: Color(0x227DEAFF), height: 24),
        const Text(
          'PUAN NEREDEN GELDİ',
          style: TextStyle(
            color: Color(0x66FFFFFF),
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _BreakdownRow(
          label: 'Hayatta kalma',
          detail: '${_result.survivalSeconds} sn',
          points: _result.survivalSeconds * GameConfig.scorePerSecond,
        ),
        _BreakdownRow(
          label: 'Vurulan düşman',
          detail:
              '${_result.enemiesDestroyed} × ${GameConfig.scorePerEnemyKilled}',
          points: _result.enemiesDestroyed * GameConfig.scorePerEnemyKilled,
        ),
        _BreakdownRow(
          label: 'Toplanan elmas',
          detail:
              '${_result.pickupsCollected} × ${GameConfig.scorePerPickupCollected}',
          points: _result.pickupsCollected * GameConfig.scorePerPickupCollected,
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

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.detail,
    required this.points,
  });

  final String label;
  final String detail;
  final int points;

  @override
  Widget build(BuildContext context) {
    // Kazanilmamis kalemler soluk gosterilir: oyuncu neyi kacirdigini gorur,
    // bir sonraki oyunda denemeye tesvik olur.
    final bool isEarned = points > 0;
    final Color textColor = isEarned
        ? const Color(0xCCFFFFFF)
        : const Color(0x55FFFFFF);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: textColor, fontSize: 12),
            ),
          ),
          Text(
            detail,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 46,
            child: Text(
              '+$points',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isEarned ? const Color(0xFF7DEAFF) : textColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
