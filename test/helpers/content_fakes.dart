import 'package:qalbee/core/utils/result.dart';
import 'package:qalbee/features/dua_tasbih/domain/entities/dua.dart';
import 'package:qalbee/features/dua_tasbih/domain/repositories/dua_repository.dart';
import 'package:qalbee/features/dua_tasbih/presentation/state/dua_store.dart';
import 'package:qalbee/features/dua_tasbih/presentation/state/tasbih_store.dart';
import 'package:qalbee/features/quran/domain/entities/ayah.dart';
import 'package:qalbee/features/quran/domain/entities/surah.dart';
import 'package:qalbee/features/quran/domain/repositories/quran_repository.dart';
import 'package:qalbee/features/quran/presentation/state/quran_store.dart';
import 'package:qalbee/features/ruqyah/domain/entities/ruqyah.dart';
import 'package:qalbee/features/ruqyah/domain/repositories/ruqyah_repository.dart';
import 'package:qalbee/features/ruqyah/presentation/state/ruqyah_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny in-memory Quran for shell-level widget tests.
final class FakeQuranRepository implements QuranRepository {
  QuranPosition? _lastRead;
  final _bookmarks = <int>{};

  static const _surahs = [
    Surah(
      id: 1,
      nameArabic: 'الفاتحة',
      transliteration: 'Al-Fatihah',
      translationEn: 'The Opener',
      ayahCount: 1,
      revelation: 'meccan',
    ),
  ];

  @override
  Future<Result<List<Surah>>> surahs() async => const Result.success(_surahs);

  @override
  Future<Result<List<Ayah>>> ayahsOf(int surah) async => const Result.success([
        Ayah(
          id: 1,
          surah: 1,
          number: 1,
          arabic: 'بِسْمِ اللَّهِ',
          translationEn: 'In the name of Allah',
          translationBn: 'আল্লাহর নামে',
        ),
      ]);

  @override
  Future<Result<List<Surah>>> searchSurahs(String query) => surahs();

  @override
  Future<Result<QuranPosition?>> lastRead() async =>
      Result.success(_lastRead);

  @override
  Future<Result<void>> setLastRead(QuranPosition position) async {
    _lastRead = position;
    return const Result.success(null);
  }

  @override
  Future<Result<Set<int>>> bookmarkedAyahIds() async =>
      Result.success(_bookmarks);

  @override
  Future<Result<void>> toggleBookmark(int ayahId) async {
    if (!_bookmarks.add(ayahId)) {
      _bookmarks.remove(ayahId);
    }
    return const Result.success(null);
  }
}

Future<QuranStore> makeQuranStore() async {
  final store = QuranStore(FakeQuranRepository(), SharedPreferencesAsync());
  await store.load();
  return store;
}

final class FakeDuaRepository implements DuaRepository {
  @override
  Future<Result<List<DuaCategory>>> categories() async =>
      const Result.success([
        DuaCategory(
          id: 'morning_evening',
          icon: 'sun',
          duas: [
            Dua(
              id: 'd1',
              arabic: 'سُبْحَانَ اللَّهِ',
              transliteration: 'SubhanAllah',
              translationEn: 'Glory be to Allah',
              translationBn: 'আল্লাহ পবিত্র',
              reference: 'Muslim 2691',
              repeat: 33,
            ),
          ],
        ),
      ]);

  @override
  Future<Result<List<AsmaName>>> asmaulHusna() async => const Result.success([
        AsmaName(
          number: 1,
          arabic: 'الرَّحْمَنُ',
          transliteration: 'Ar-Rahman',
          meaningEn: 'The Most Merciful',
          meaningBn: 'পরম দয়ালু',
        ),
      ]);
}

Future<DuaStore> makeDuaStore() async {
  final store = DuaStore(FakeDuaRepository());
  await store.load();
  return store;
}

final class FakeRuqyahRepository implements RuqyahRepository {
  @override
  Future<Result<List<RuqyahCategory>>> categories() async =>
      const Result.success([
        RuqyahCategory(
          id: 'protection',
          icon: 'shield',
          items: [
            RuqyahItem(
              id: 'ayatul_kursi',
              titleEn: 'Ayatul Kursi',
              titleBn: 'আয়াতুল কুরসি',
              arabic: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
              transliteration: 'Allahu la ilaha illa huwa',
              translationEn: 'Allah — there is no god but He',
              translationBn: 'আল্লাহ — তিনি ছাড়া কোনো ইলাহ নেই',
              reference: 'Qur\'an 2:255',
              repeat: 3,
            ),
          ],
        ),
      ]);
}

Future<RuqyahStore> makeRuqyahStore() async {
  final store = RuqyahStore(FakeRuqyahRepository());
  await store.load();
  return store;
}

/// Tasbih counter for shell-level widget tests — no-op haptics so no
/// platform channels are touched.
Future<TasbihStore> makeTasbihStore() async {
  final store = TasbihStore(
    SharedPreferencesAsync(),
    haptic: () {},
    milestoneHaptic: () {},
  );
  await store.load();
  return store;
}
