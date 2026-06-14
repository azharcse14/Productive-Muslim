import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/hadith_book.dart';
import '../../domain/repositories/hadith_book_repository.dart';

/// Read-only state for the bundled hadith-book catalog.
final class HadithBooksStore {
  HadithBooksStore(this._repository);

  final HadithBookRepository _repository;

  late final books = signal(const <HadithBook>[]);
  late final loaded = signal(false);

  Future<void> load() async {
    final result = await _repository.books();
    if (result.valueOrNull case final value?) {
      books.value = value;
    }
    loaded.value = true;
  }
}
