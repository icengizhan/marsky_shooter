import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/key_value_store.dart';
import '../../data/datasources/shared_prefs_key_value_store.dart';
import '../../data/repositories/score_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/score_repository.dart';
import '../../domain/repositories/settings_repository.dart';

/// Bagimlilik grafiginin kokleri.
///
/// Uygulamanin geri kalani yalnizca ARAYUZLERI (`KeyValueStore`,
/// `ScoreRepository`) gorur; hangi somut sinifin kullanildigi tek yerde,
/// burada belirlenir. Testte `ProviderScope(overrides: [...])` ile bu iki
/// provider degistirilerek tum uygulama sahte veriyle calistirilabilir --
/// SOLID'in Dependency Inversion maddesinin pratik karsiligi.

/// Cihaz uzerindeki kalici anahtar-deger deposu.
final Provider<KeyValueStore> keyValueStoreProvider = Provider<KeyValueStore>(
  (Ref ref) => SharedPrefsKeyValueStore(),
);

/// Skor kaliciligi. Somut uygulama yalnizca burada biliniyor.
final Provider<ScoreRepository> scoreRepositoryProvider =
    Provider<ScoreRepository>(
      (Ref ref) => ScoreRepositoryImpl(ref.watch(keyValueStoreProvider)),
    );

/// Ayar kaliciligi (ses ac/kapa).
///
/// Skorlarla AYNI deseni kullanir: sunum katmani `KeyValueStore`a dogrudan
/// erismez, hangi anahtarla saklandigini bilmez.
final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>(
      (Ref ref) => SettingsRepositoryImpl(ref.watch(keyValueStoreProvider)),
    );
