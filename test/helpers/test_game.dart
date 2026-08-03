import 'package:marsky_shooter/game/audio/game_audio.dart';
import 'package:marsky_shooter/game/marsky_game.dart';

/// Testler icin sessiz oyun ornegi.
///
/// Gercek `FlameGameAudio`, arka planda `path_provider` platform kanalini
/// kullanir; unit test ortaminda bu kanal yoktur ve `MissingPluginException`
/// atilir. [SilentGameAudio] enjekte edilerek oyun sessiz ayaga kaldirilir.
MarskyGame createSilentGame() => MarskyGame(audio: SilentGameAudio());
