import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/key_value_store.dart';
import '../../data/datasources/shared_prefs_key_value_store.dart';
import '../../data/repositories/score_repository_impl.dart';
import '../../domain/repositories/score_repository.dart';

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
