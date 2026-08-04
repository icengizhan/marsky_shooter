import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/data/datasources/storage_keys.dart';
import 'package:marsky_shooter/data/repositories/settings_repository_impl.dart';
import 'package:marsky_shooter/domain/repositories/settings_repository.dart';

import '../helpers/in_memory_key_value_store.dart';

void main() {
  late InMemoryKeyValueStore store;
  late SettingsRepository repository;

  setUp(() {
    store = InMemoryKeyValueStore();
    repository = SettingsRepositoryImpl(store);
  });

  group('SettingsRepositoryImpl', () {
    test('kayit yoksa ses ACIK varsayilir', () async {
      // Varsayilanin repository'de olmasi onemli: sunum katmani "kayit yoksa ne
      // olacak" sorusunu bilmemeli.
      expect(await repository.readSoundEnabled(), isTrue);
    });

    test('yazilan deger geri okunur', () async {
      await repository.writeSoundEnabled(false);
      expect(await repository.readSoundEnabled(), isFalse);

      await repository.writeSoundEnabled(true);
      expect(await repository.readSoundEnabled(), isTrue);
    });

    test('beklenen anahtari kullanir', () async {
      await repository.writeSoundEnabled(false);

      expect(
        store.values[StorageKeys.soundEnabled],
        isFalse,
        reason: 'anahtar degisirse kullanicinin kayitli ayari kaybolur',
      );
    });
  });

  group('StorageKeys', () {
    test('anahtarlar birbirinden farkli', () {
      final Set<String> keys = <String>{
        StorageKeys.highScore,
        StorageKeys.scoreHistory,
        StorageKeys.soundEnabled,
      };

      expect(
        keys.length,
        3,
        reason: 'ayni anahtarin iki yerde kullanilmasi veriyi ezer',
      );
    });

    test('hepsi marsky onekli', () {
      for (final String key in <String>[
        StorageKeys.highScore,
        StorageKeys.scoreHistory,
        StorageKeys.soundEnabled,
      ]) {
        expect(
          key.startsWith('marsky.'),
          isTrue,
          reason: 'onek olmadan baska uygulama verileriyle karisabilir',
        );
      }
    });
  });
}
