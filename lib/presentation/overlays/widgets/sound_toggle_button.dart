import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_providers.dart';

/// Ses ac/kapa dugmesi.
///
/// Ayar Riverpod'da tutulur ve diske yazilir; bu widget yalnizca okur ve
/// degistirir. Oyunun ses kapisina uygulama isini `GameScreen` yapar.
class SoundToggleButton extends ConsumerWidget {
  const SoundToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> soundEnabled = ref.watch(soundEnabledProvider);

    // Ayar diskten okunurken (loading) ses acik varsayilir; ikon titremesin.
    final bool isEnabled = soundEnabled.value ?? true;

    return IconButton(
      onPressed: () => ref.read(soundEnabledProvider.notifier).toggle(),
      tooltip: isEnabled ? 'Sesi kapat' : 'Sesi ac',
      icon: Icon(
        isEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        color: const Color(0xFFB8E9F5),
      ),
    );
  }
}
