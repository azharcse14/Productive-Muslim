import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../config/app_config.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';

/// App-scoped Quran state: the surah index, resume position, bookmarks
/// and reader preferences (independent Arabic scale + translation toggle,
/// persisted separately from the system font scale — design §4.5).
final class QuranStore {
  QuranStore(this._repository, this._prefs);

  static const _fontSizeKey = 'quran_font_size';
  static const _showTranslationKey = 'quran_show_translation';
  static const _defaultFontSize = 28.0;

  final QuranRepository _repository;
  final SharedPreferencesAsync _prefs;

  late final surahs = signal(const <Surah>[]);
  late final lastRead = signal<QuranPosition?>(null);

  /// Global ayah ids (1..6236).
  late final bookmarks = signal(const <int>{});

  late final readerFontSize = signal(_defaultFontSize);
  late final showTranslation = signal(true);
  late final loaded = signal(false);

  Future<void> load() async {
    surahs.value = (await _repository.surahs()).valueOrNull ?? const [];
    lastRead.value = (await _repository.lastRead()).valueOrNull;
    bookmarks.value =
        (await _repository.bookmarkedAyahIds()).valueOrNull ?? const {};
    readerFontSize.value = _clampFontSize(
      await _prefs.getDouble(_fontSizeKey) ?? _defaultFontSize,
    );
    showTranslation.value = await _prefs.getBool(_showTranslationKey) ?? true;
    loaded.value = true;
  }

  /// Index search — debounced by the caller.
  Future<List<Surah>> search(String query) async =>
      (await _repository.searchSurahs(query)).valueOrNull ?? const [];

  /// Ayahs for the reader, ordered by number within the surah.
  Future<List<Ayah>> ayahsOf(int surah) async =>
      (await _repository.ayahsOf(surah)).valueOrNull ?? const [];

  /// Records the reading position; the reader calls this as ayahs become
  /// visible, so the Quran tab can offer "continue reading".
  Future<void> markRead(QuranPosition position) async {
    lastRead.value = position;
    await _repository.setLastRead(position);
  }

  Future<void> toggleBookmark(int ayahId) async {
    final next = {...bookmarks.value};
    if (!next.remove(ayahId)) {
      next.add(ayahId);
    }
    bookmarks.value = next;
    await _repository.toggleBookmark(ayahId);
  }

  /// Maps a global ayah id (1..6236) to surah/ayah via the index's ayah
  /// counts; null before [load] or for an out-of-range id.
  QuranPosition? positionOf(int ayahId) {
    var remaining = ayahId;
    for (final surah in surahs.value) {
      if (remaining <= surah.ayahCount) {
        return remaining < 1 ? null : QuranPosition(surah.id, remaining);
      }
      remaining -= surah.ayahCount;
    }
    return null;
  }

  Future<void> setReaderFontSize(double size) async {
    final clamped = _clampFontSize(size);
    readerFontSize.value = clamped;
    await _prefs.setDouble(_fontSizeKey, clamped);
  }

  Future<void> setShowTranslation({required bool value}) async {
    showTranslation.value = value;
    await _prefs.setBool(_showTranslationKey, value);
  }

  static double _clampFontSize(double size) => size
      .clamp(AppConfig.quranFontSizeMin, AppConfig.quranFontSizeMax)
      .toDouble();
}
