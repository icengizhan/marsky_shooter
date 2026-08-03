import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/score_entry.dart';
import '../../game/marsky_game.dart';
import '../providers/score_providers.dart';
import 'widgets/how_to_play.dart';
import 'widgets/overlay_panel.dart';
import 'widgets/sound_toggle_button.dart';

/// Ana menu: baslat butonu, en yuksek skor ve son skorlar.
/// (case PDF §2.B: "Ana Menü: Başla butonu ve en yüksek skor gösterimi")
///
/// Arka planda oyun motoru CALISMAYA DEVAM EDER (yildizlar kayar); yalnizca
/// dusman olusturma ve ates gecici olarak kapalidir. Motoru tamamen durdurmak
/// daha kolay olurdu ama menu olu bir ekran gibi gorunurdu.
class MainMenuOverlay extends ConsumerWidget {
  const MainMenuOverlay({required this.game, super.key});

  final MarskyGame game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<int> highScore = ref.watch(highScoreProvider);
    final AsyncValue<List<ScoreEntry>> history = ref.watch(
      scoreHistoryProvider,
    );

    return OverlayPanel(
      title: 'MARSKY',
      subtitle: 'TOP-DOWN SHOOTER',
      children: <Widget>[
        StatRow(
          label: 'EN YÜKSEK SKOR',
          // Diskten okunurken '—' gosterilir; sifir gostermek yanlis bilgi olur.
          value: highScore.when(
            data: (int value) => '$value',
            loading: () => '—',
            error: (Object _, StackTrace _) => '—',
          ),
        ),
        const SizedBox(height: 8),
        _RecentScores(history: history),
        const HowToPlay(),
        const SizedBox(height: 20),
        MenuButton(label: 'BAŞLA', onPressed: game.startGame),
        const SoundToggleButton(),
      ],
    );
  }
}

class _RecentScores extends StatelessWidget {
  const _RecentScores({required this.history});

  final AsyncValue<List<ScoreEntry>> history;

  @override
  Widget build(BuildContext context) {
    final List<ScoreEntry> entries = history.value ?? <ScoreEntry>[];
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Divider(color: Color(0x227DEAFF), height: 20),
        const Text(
          'SON OYUNLAR',
          style: TextStyle(
            color: Color(0x66FFFFFF),
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        for (final ScoreEntry entry in entries.take(3))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  _formatDate(entry.achievedAt),
                  style: const TextStyle(
                    color: Color(0x88FFFFFF),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${entry.points}',
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month  $hour:$minute';
  }
}
