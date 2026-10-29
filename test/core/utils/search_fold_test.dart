import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/search_fold.dart';

void main() {
  group('foldForSearch', () {
    test('lowercases Latin text', () {
      expect(foldForSearch('Ayatul KURSI'), 'ayatul kursi');
    });

    test('folds Bengali base + nukta to the precomposed letter', () {
      // য + ় → য় (U+09DF), ড + ় → ড় (U+09DC), ঢ + ় → ঢ় (U+09DD).
      expect(foldForSearch('য়'), 'য়');
      expect(foldForSearch('ড়'), 'ড়');
      expect(foldForSearch('ঢ়'), 'ঢ়');
      expect(
        foldForSearch('আয়াত'),
        foldForSearch('আয়াত'),
      );
    });

    test('drops ZWNJ / ZWJ', () {
      expect(foldForSearch('নাফ্‌সী'), 'নাফ্সী');
      expect(foldForSearch('র‍্যাব'), 'র্যাব');
    });

    test('drops Arabic harakat, so plain typed Arabic matches', () {
      expect(foldForSearch('بِسْمِ اللَّهِ'), 'بسم الله');
      expect(foldForSearch('رَحْمَةً'), 'رحمة');
    });

    test('drops Quranic marks, superscript alef and tatweel', () {
      expect(foldForSearch('ٱلرَّحْمَـٰنِ'), 'الرحمن');
      expect(foldForSearch('عَلِيمٌ ۚ'), 'عليم ');
      expect(foldForSearch('هُوَ ۖ'), 'هو ');
    });

    test('unifies alef forms to bare alef', () {
      expect(foldForSearch('آ أ إ ٱ ا'), 'ا ا ا ا ا');
      expect(foldForSearch('إِنَّا'), foldForSearch('انا'));
    });

    test('leaves already-folded text unchanged', () {
      const plain = 'সুবহানাল্লাহ subhanallah سبحان';
      expect(foldForSearch(plain), plain);
      expect(foldForSearch(foldForSearch('ٱلْحَمْدُ')), foldForSearch('ٱلْحَمْدُ'));
    });
  });
}
