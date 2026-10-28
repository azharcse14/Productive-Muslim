import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/quran/data/datasources/quran_database.dart';
import 'package:productive_muslim/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:productive_muslim/features/quran/domain/entities/ayah.dart';

void main() {
  // The committed asset must never be written to (the beforeOpen hook
  // creates user tables), so every test opens a temp copy.
  late Directory tempDir;
  late QuranDatabase db;
  late QuranRepositoryImpl repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('productive_muslim_quran_db_test');
    final copy = File('${tempDir.path}/quran.db');
    await File('assets/data/quran.db').copy(copy.path);
    db = QuranDatabase(NativeDatabase(copy));
    repo = QuranRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  group('surahs', () {
    test('returns all 114 surahs ordered by id', () async {
      final result = await repo.surahs();
      final surahs = result.valueOrNull;
      expect(surahs, isNotNull);
      expect(surahs!.length, 114);
      expect([for (final s in surahs) s.id], List.generate(114, (i) => i + 1));
      expect(surahs.first.transliteration, 'Al-Faatiha');
      expect(surahs.first.ayahCount, 7);
      expect(surahs.first.revelation, 'meccan');
    });
  });

  group('ayahsOf', () {
    test('returns the 7 ayahs of surah 1 ordered by number', () async {
      final result = await repo.ayahsOf(1);
      final ayahs = result.valueOrNull;
      expect(ayahs, isNotNull);
      expect(ayahs!.length, 7);
      expect([for (final a in ayahs) a.number], [1, 2, 3, 4, 5, 6, 7]);
      expect(ayahs.first.surah, 1);
      expect(ayahs.first.arabic, isNotEmpty);
      expect(ayahs.first.translationEn, isNotEmpty);
    });
  });

  group('searchSurahs', () {
    test("'fatiha' finds Al-Faatiha despite the doubled vowel", () async {
      final result = await repo.searchSurahs('fatiha');
      expect([for (final s in result.valueOrNull!) s.id], [1]);
    });

    test("'cow' finds Al-Baqara via translation_en", () async {
      final result = await repo.searchSurahs('cow');
      final surahs = result.valueOrNull!;
      expect([for (final s in surahs) s.id], [2]);
      expect(surahs.single.transliteration, 'Al-Baqara');
    });

    test('a surah number matches in Western and Bengali digits', () async {
      expect([for (final s in (await repo.searchSurahs('2')).valueOrNull!) s.id],
          [2]);
      expect(
          [for (final s in (await repo.searchSurahs('১১৪')).valueOrNull!) s.id],
          [114]);
    });

    test('an Arabic query matches nameArabic ignoring diacritics', () async {
      final all = (await repo.surahs()).valueOrNull!;
      final ikhlas = all.firstWhere((s) => s.id == 112);
      final result = await repo.searchSurahs(ikhlas.nameArabic);
      expect([for (final s in result.valueOrNull!) s.id], contains(112));
      expect((await repo.searchSurahs('الاخلاص')).valueOrNull!.map((s) => s.id),
          contains(112));
    });

    test('an unmatchable non-Latin query returns nothing, not everything',
        () async {
      expect((await repo.searchSurahs('ফাতিহা')).valueOrNull, isEmpty);
    });

    test('empty query returns all 114 surahs in order', () async {
      final result = await repo.searchSurahs('');
      final surahs = result.valueOrNull!;
      expect(surahs.length, 114);
      expect(surahs.first.id, 1);
      expect(surahs.last.id, 114);
    });
  });

  group('lastRead', () {
    test('is null before any position is stored', () async {
      final result = await repo.lastRead();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('set → read round-trips and upserts on id 1', () async {
      await repo.setLastRead(const QuranPosition(2, 255));
      expect((await repo.lastRead()).valueOrNull, const QuranPosition(2, 255));

      // Second write must update the single row, not fail on the PK.
      await repo.setLastRead(const QuranPosition(18, 10));
      expect((await repo.lastRead()).valueOrNull, const QuranPosition(18, 10));
    });
  });

  group('bookmarks', () {
    test('starts empty and toggle adds/removes persistently', () async {
      expect((await repo.bookmarkedAyahIds()).valueOrNull, isEmpty);

      await repo.toggleBookmark(5);
      await repo.toggleBookmark(262);
      expect((await repo.bookmarkedAyahIds()).valueOrNull, {5, 262});

      await repo.toggleBookmark(5);
      expect((await repo.bookmarkedAyahIds()).valueOrNull, {262});
    });
  });
}
