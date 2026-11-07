import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/config/assets.dart';
import 'package:productive_muslim/shared/widgets/q_arabic_span.dart';

void main() {
  const hafs = TextStyle(fontFamily: AppFonts.quran, fontSize: 20);

  test('text without U+060C stays one Hafs span', () {
    final span = hafsSpan('بِسْمِ اللَّهِ', hafs);
    expect(span.text, 'بِسْمِ اللَّهِ');
    expect(span.children, isNull);
    expect(span.style, hafs);
  });

  test('U+060C is drawn in the UI Arabic font, the rest in Hafs', () {
    const text = 'أَصْبَحْنَا، وَأَصْبَحَ،';
    final span = hafsSpan(text, hafs);
    expect(span.toPlainText(), text);
    expect(span.style, hafs);
    final children = span.children!.cast<TextSpan>();
    final commas = children.where((c) => c.text == '،').toList();
    expect(commas, hasLength(2));
    for (final c in commas) {
      expect(c.style!.fontFamily, AppFonts.arabicUi);
      expect(c.style!.fontSize, 20);
    }
    for (final c in children.where((c) => c.text != '،')) {
      expect(c.style, isNull, reason: 'inherits Hafs from the parent');
    }
  });

  test('؟ and ؛ also leave Hafs, consecutive marks stay one span', () {
    const text = 'أَيْنَ؟ قَالَ؛ نَعَمْ،؟';
    final span = hafsSpan(text, hafs);
    expect(span.toPlainText(), text);
    final ui = span.children!
        .cast<TextSpan>()
        .where((c) => c.style?.fontFamily == AppFonts.arabicUi)
        .map((c) => c.text)
        .toList();
    expect(ui, ['؟', '؛', '،؟']);
  });
}
