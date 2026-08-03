import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:marsky_shooter/core/config/game_config.dart';
import 'package:marsky_shooter/data/datasources/key_value_store.dart';
import 'package:marsky_shooter/data/repositories/score_repository_impl.dart';
import 'package:marsky_shooter/domain/entities/score_entry.dart';
import 'package:mocktail/mocktail.dart';

/// Sahte depo. `KeyValueStore` bir arayuz oldugu icin taklidi tek satir --
/// gercek `shared_preferences` kullanilsaydi platform kanali kurmak
/// gerekirdi. Bu, araya soyutlama koymanin somut kazanci.
class _MockKeyValueStore extends Mock implements KeyValueStore {}

void main() {
  late _MockKeyValueStore store;
  late ScoreRepositoryImpl repository;

  setUp(() {
    store = _MockKeyValueStore();
    repository = ScoreRepositoryImpl(store);
  });

  group('ScoreRepositoryImpl - yuksek skor', () {
    test('hic kayit yoksa 0 doner', () async {
      when(() => store.readInt(any())).thenAnswer((_) async => null);

      expect(await repository.readHighScore(), 0);
    });

    test('kayitli deger oldugu gibi doner', () async {
      when(() => store.readInt(any())).thenAnswer((_) async => 742);

      expect(await repository.readHighScore(), 742);
    });

    test('daha yuksek skor yazilir ve true doner', () async {
      when(() => store.readInt(any())).thenAnswer((_) async => 100);
      when(() => store.writeInt(any(), any())).thenAnswer((_) async {});

      expect(await repository.writeHighScoreIfHigher(150), isTrue);
      verify(
        () => store.writeInt(ScoreRepositoryImpl.highScoreKey, 150),
      ).called(1);
    });

    test('daha dusuk skor YAZILMAZ ve false doner', () async {
      when(() => store.readInt(any())).thenAnswer((_) async => 200);

      expect(await repository.writeHighScoreIfHigher(150), isFalse);
      verifyNever(() => store.writeInt(any(), any()));
    });

    test('esit skor yazilmaz (gereksiz disk yazmasi olmaz)', () async {
      when(() => store.readInt(any())).thenAnswer((_) async => 150);

      expect(await repository.writeHighScoreIfHigher(150), isFalse);
      verifyNever(() => store.writeInt(any(), any()));
    });
  });

  group('ScoreRepositoryImpl - skor gecmisi', () {
    test('kayit yoksa bos liste doner', () async {
      when(() => store.readString(any())).thenAnswer((_) async => null);

      expect(await repository.readHistory(), isEmpty);
    });

    test('bozuk/bos metin cokme yerine bos liste verir', () async {
      when(() => store.readString(any())).thenAnswer((_) async => '');

      expect(await repository.readHistory(), isEmpty);
    });

    test('yeni kayit basa eklenir', () async {
      final ScoreEntry older = ScoreEntry(
        points: 10,
        achievedAt: DateTime.utc(2026, 8, 1),
      );
      when(() => store.readString(any())).thenAnswer(
        (_) async => jsonEncode(<Map<String, dynamic>>[older.toJson()]),
      );

      String? written;
      when(() => store.writeString(any(), any())).thenAnswer((
        Invocation invocation,
      ) async {
        written = invocation.positionalArguments[1] as String;
      });

      final ScoreEntry newest = ScoreEntry(
        points: 999,
        achievedAt: DateTime.utc(2026, 8, 3),
      );
      await repository.appendToHistory(newest);

      final List<ScoreEntry> decoded = _decode(written);
      expect(decoded.first, newest, reason: 'en yeni kayit basta olmali');
      expect(decoded.length, 2);
    });

    test('gecmis azami uzunlugu asmaz (sinirsiz buyume olmaz)', () async {
      // Depo zaten dolu.
      final List<ScoreEntry> full = List<ScoreEntry>.generate(
        GameConfig.maxScoreHistoryEntries,
        (int i) =>
            ScoreEntry(points: i, achievedAt: DateTime.utc(2026, 1, 1 + i)),
      );
      when(() => store.readString(any())).thenAnswer(
        (_) async => jsonEncode(
          full.map((ScoreEntry e) => e.toJson()).toList(growable: false),
        ),
      );

      String? written;
      when(() => store.writeString(any(), any())).thenAnswer((
        Invocation invocation,
      ) async {
        written = invocation.positionalArguments[1] as String;
      });

      await repository.appendToHistory(
        ScoreEntry(points: 999, achievedAt: DateTime.utc(2026, 8, 3)),
      );

      final List<ScoreEntry> decoded = _decode(written);
      expect(decoded.length, GameConfig.maxScoreHistoryEntries);
      expect(decoded.first.points, 999);
      // En eski kayit dusmus olmali.
      expect(
        decoded.any((ScoreEntry e) => e.points == full.last.points),
        isFalse,
      );
    });
  });
}

List<ScoreEntry> _decode(String? raw) {
  expect(raw, isNotNull, reason: 'depoya yazma yapilmali');
  return (jsonDecode(raw!) as List<dynamic>)
      .map(
        (dynamic item) => ScoreEntry.fromJson(item as Map<String, dynamic>),
      )
      .toList(growable: false);
}
