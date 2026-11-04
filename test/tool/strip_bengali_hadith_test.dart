import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/hadith/data/hadith_book_catalog_data_source.dart';

import '../../tool/strip_bengali_hadith.dart';

/// Serves one string for every asset key.
final class _StringBundle extends CachingAssetBundle {
  _StringBundle(this.text);

  final String text;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
}

void main() {
  test(
    'a stripped catalog still loads every book, none in hadithbangla',
    () async {
      final catalog =
          jsonDecode(File('assets/data/hadith_books.json').readAsStringSync())
              as Map<String, dynamic>;
      final before = (catalog['books'] as List).length;
      expect(stripCatalog(catalog), 6); // the six hadithbangla books

      final text = jsonEncode(catalog);
      expect(text, isNot(contains('sections_bn')));
      expect(text, isNot(contains('bn_folder')));

      final books = await HadithBookCatalogDataSource(
        _StringBundle(text),
      ).loadBooks();
      expect(books, hasLength(before));
      for (final book in books) {
        expect(book.usesBanglaSource('bn'), isFalse, reason: book.id);
        expect(book.sectionsFor('bn'), isNotEmpty, reason: book.id);
      }
    },
  );
}
