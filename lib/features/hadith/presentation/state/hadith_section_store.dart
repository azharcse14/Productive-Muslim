import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/hadith_book.dart';
import '../../domain/repositories/hadith_book_repository.dart';

/// Loading state for one section of a book — fetches hadith on demand and
/// exposes a simple loading/error/data tri-state for the reader screen.
final class HadithSectionStore {
  HadithSectionStore(this._repository);

  final HadithBookRepository _repository;

  late final items = signal(const <BookHadith>[]);
  late final loading = signal(false);

  /// True when the last load failed — the screen offers a retry.
  late final failed = signal(false);

  Future<void> load(
    HadithBook book,
    HadithSection section,
    String languageCode,
  ) async {
    loading.value = true;
    failed.value = false;
    final result =
        await _repository.section(book, section, languageCode);
    if (result.valueOrNull case final value?) {
      items.value = value;
    } else {
      failed.value = true;
    }
    loading.value = false;
  }

  void dispose() {
    items.dispose();
    loading.dispose();
    failed.dispose();
  }
}
