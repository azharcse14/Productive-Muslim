import 'package:flutter_test/flutter_test.dart';

import '../../tool/hadith_db_build.dart';

Map<String, Object?> _h(num n, int book, [String text = 'x']) => {
  'hadithnumber': n,
  'text': text,
  'reference': {'book': book, 'hadith': 0},
};

Map<String, Object?> _info({
  required List<Map<String, Object?>> hadiths,
  String name0 = '',
  int first0 = 0,
  int last0 = 0,
}) => {
  'metadata': {
    'sections': {'0': name0, '1': 'One', '2': 'Two'},
    'section_details': {
      '0': {'hadithnumber_first': first0, 'hadithnumber_last': last0},
    },
  },
  'hadiths': hadiths,
};

void main() {
  group('placeSectionZero', () {
    test('a stray joins the chapter of the hadith it follows', () {
      final info = _info(
        hadiths: [_h(1, 1), _h(2, 0), _h(3, 1), _h(4, 0), _h(5, 2)],
      );
      final placed = placeSectionZero(info, [_h(2, 0), _h(4, 0)], {1, 2});
      // 4 sits between chapters 1 and 2: stays with the one it follows.
      expect(placed, {2: 1, 4: 1});
    });

    test('a leading stray takes the following chapter', () {
      final info = _info(hadiths: [_h(1, 0), _h(2, 1)]);
      expect(placeSectionZero(info, [_h(1, 0)], {1}), {1: 1});
    });

    test('a named section 0 keeps the numbers in its range', () {
      final info = _info(
        name0: 'Introduction',
        first0: 1,
        last0: 2,
        hadiths: [_h(1, 0), _h(2, 0), _h(3, 1), _h(4, 0)],
      );
      expect(placeSectionZero(info, [_h(1, 0), _h(4, 0)], {0, 1}), {
        1: 0,
        4: 1,
      });
    });

    test('hadith empty in every edition are left out', () {
      final info = _info(hadiths: [_h(1, 1), _h(2, 0)]);
      expect(placeSectionZero(info, [_h(2, 0, ' ')], {1}), isEmpty);
      // Text in one edition is enough.
      expect(placeSectionZero(info, [_h(2, 0, ''), _h(2, 0, 'en')], {1}), {
        2: 1,
      });
    });

    test('a target the catalog lacks throws instead of dropping it', () {
      final info = _info(hadiths: [_h(1, 2), _h(2, 0)]);
      expect(() => placeSectionZero(info, [_h(2, 0)], {1}), throwsStateError);
    });
  });

  test('mergeByNumber inserts by hadithnumber, keeping upstream order', () {
    final merged = mergeByNumber(
      [_h(1, 1), _h(3, 1), _h(3.2, 1)],
      [_h(2, 0), _h(4, 0)],
    );
    expect([for (final h in merged) h['hadithnumber']], [1, 2, 3, 3.2, 4]);
  });
}
