import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/key_value_store.dart';
import 'app_providers.dart';

/// Ses acik/kapali ayari (kalici).
///
/// Case PDF §3 "Oyun dışı UI state'leri (ses ayarları, skor geçmişi vb.) için
/// standart bir State Management çözümü" istiyor -- bu provider tam olarak o
/// maddenin karsiligi. Deger degistiginde `GameScreen` bunu dinleyip oyunun
/// [GameAudio] kapisina uygular; oyun motoru Riverpod'u hic bilmez.
class SoundEnabledNotifier extends AsyncNotifier<bool> {
  static const String _storageKey = 'marsky.sound_enabled';

  @override
  Future<bool> build() async {
    final KeyValueStore store = ref.watch(keyValueStoreProvider);
    // Ilk kurulumda ses acik olsun.
    return await store.readBool(_storageKey) ?? true;
  }

  Future<void> toggle() async {
    final bool next = !(state.value ?? true);
    // Once UI guncellenir (aninda tepki), sonra diske yazilir.
    state = AsyncValue<bool>.data(next);
    await ref.read(keyValueStoreProvider).writeBool(_storageKey, next);
  }
}

final AsyncNotifierProvider<SoundEnabledNotifier, bool> soundEnabledProvider =
    AsyncNotifierProvider<SoundEnabledNotifier, bool>(SoundEnabledNotifier.new);
