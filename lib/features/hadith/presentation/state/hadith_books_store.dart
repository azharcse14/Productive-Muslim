import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/hadith_book.dart';
import '../../domain/repositories/hadith_book_repository.dart';

/// The last opened chapter: book id, section number and the language whose
/// chapter list that number belongs to (Bengali and English lists differ),
/// plus the reader's scroll offset in it.
typedef HadithResume = ({
  String bookId,
  String languageCode,
  int section,
  double offset,
});

/// Read-only state for the bundled hadith-book catalog, plus the last
/// opened chapter for "continue reading".
final class HadithBooksStore {
  HadithBooksStore(this._repository, [SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _resumeKey = 'hadith_last_section';

  final HadithBookRepository _repository;
  final SharedPreferencesAsync _prefs;

  late final books = signal(const <HadithBook>[]);
  late final loaded = signal(false);

  /// The last load failed; the screen offers a retry.
  late final failed = signal(false);

  late final lastOpened = signal<HadithResume?>(null);

  Future<void> load() async {
    final result = await _repository.books();
    if (result.valueOrNull case final value?) {
      books.value = value;
    }
    failed.value = result.valueOrNull == null;
    lastOpened.value = _decode(await _prefs.getString(_resumeKey));
    loaded.value = true;
  }

  /// Records [section] as the chapter to continue; reopening the same one
  /// keeps its saved scroll offset.
  Future<void> markOpened(
    HadithBook book,
    HadithSection section,
    String languageCode,
  ) => _save(
    book,
    section,
    languageCode,
    savedOffset(book, section, languageCode),
  );

  /// Saves the reader's scroll [offset] within [section].
  Future<void> saveOffset(
    HadithBook book,
    HadithSection section,
    String languageCode,
    double offset,
  ) => _save(book, section, languageCode, offset);

  /// The saved scroll offset for [section], or 0 when it isn't the
  /// last opened chapter.
  double savedOffset(
    HadithBook book,
    HadithSection section,
    String languageCode,
  ) {
    final resume = lastOpened.value;
    return resume != null &&
            resume.bookId == book.id &&
            resume.languageCode == languageCode &&
            resume.section == section.number
        ? resume.offset
        : 0;
  }

  Future<void> _save(
    HadithBook book,
    HadithSection section,
    String languageCode,
    double offset,
  ) async {
    lastOpened.value = (
      bookId: book.id,
      languageCode: languageCode,
      section: section.number,
      offset: offset,
    );
    await _prefs.setString(
      _resumeKey,
      '${book.id}|$languageCode|${section.number}|${offset.round()}',
    );
  }

  /// The saved chapter resolved against the loaded catalog for
  /// [languageCode]; null when none, or saved under another language.
  (HadithBook, HadithSection)? resumeFor(String languageCode) {
    final resume = lastOpened.value;
    if (resume == null || resume.languageCode != languageCode) {
      return null;
    }
    final book = books.value.where((b) => b.id == resume.bookId).firstOrNull;
    final section = book
        ?.sectionsFor(languageCode)
        .where((s) => s.number == resume.section)
        .firstOrNull;
    return section == null ? null : (book!, section);
  }

  static HadithResume? _decode(String? raw) {
    final parts = raw?.split('|');
    // 3 parts: saved before the scroll offset was stored.
    if (parts == null || parts.length < 3 || parts.length > 4) {
      return null;
    }
    final section = int.tryParse(parts[2]);
    final offset = parts.length == 4 ? double.tryParse(parts[3]) ?? 0 : 0.0;
    return section == null
        ? null
        : (
            bookId: parts[0],
            languageCode: parts[1],
            section: section,
            offset: offset,
          );
  }
}
