import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/settings_repository.dart';
import 'app_providers.dart';

/// Ses acik/kapali ayari (kalici).
///
/// Case PDF §3 "Oyun dışı UI state'leri (ses ayarları, skor geçmişi vb.) için
/// standart bir State Management çözümü" istiyor -- bu provider tam olarak o
/// maddenin karsiligi. Deger degistiginde `GameScreen` bunu dinleyip oyunun
/// ses kapisina uygular; oyun motoru Riverpod'u hic bilmez.
///
/// Kalicilik [SettingsRepository] uzerinden yapilir; bu sinif hangi anahtarla
/// veya hangi tipte saklandigini BILMEZ. Onceden `KeyValueStore`a dogrudan
/// erisiliyordu ve bu, skorlar icin kullanilan repository desenini atliyordu.
class SoundEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.watch(settingsRepositoryProvider).readSoundEnabled();

  Future<void> toggle() async {
    final bool next = !(state.value ?? true);
    // Once UI guncellenir (aninda tepki), sonra diske yazilir.
    state = AsyncValue<bool>.data(next);
    await ref.read(settingsRepositoryProvider).writeSoundEnabled(next);
  }
}

final AsyncNotifierProvider<SoundEnabledNotifier, bool> soundEnabledProvider =
    AsyncNotifierProvider<SoundEnabledNotifier, bool>(SoundEnabledNotifier.new);
