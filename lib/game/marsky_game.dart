import 'dart:ui';

import 'package:flame/game.dart';

import '../core/config/game_config.dart';

/// Oyunun kok (root) sinifi.
///
/// Su an yalnizca bos bir uzay tuvali cizer. Faz 4'te oyuncu, dusman, mermi ve
/// arka plan component'leri buraya eklenecek; bu sinif bir "kompozisyon koku"
/// olarak kalacak -- oyun mantigi ICINE yazilmayacak, ayri Component
/// siniflarina dagitilacak (case PDF §3: "Tüm oyun mantığı tek bir sınıfa
/// yığılmamalıdır").
///
/// FlameGame (Flame — https://docs.flame-engine.org/latest/flame/game.html)
class MarskyGame extends FlameGame {
  /// FlameGame.backgroundColor() (Flame — src/game/game.dart)
  /// Tuvalin her karede temizlendigi renk.
  @override
  Color backgroundColor() => GameConfig.spaceColor;
}
