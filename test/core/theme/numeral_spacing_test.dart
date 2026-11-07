// SchibstedGrotesk's `tnum` widens `, . : %` to figure width ("300 ,000",
// "6 : 07"). Measured with the real fonts so a regression shows up as width.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/theme/productive_muslim_typography.dart';

import '../../store/store_capture.dart';

double _width(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  test('num_: separators keep their natural width', () {
    final plain = QType.body;
    final num = QType.num_(QType.body);
    for (final value in ['300,000', '37.5%', '6:07', '৬:০৭', '৩৭.৫%']) {
      // Same width as the untouched style: no figure-width punctuation.
      expect(_width(value, num), closeTo(_width(value, plain), 0.01));
    }
    // A comma is far narrower than a digit, so "300,000" sits well under
    // seven digits wide (it was wider under tnum).
    expect(_width('300,000', num), lessThan(_width('3000000', num)));
  });

  test('countdownDigit: digits tabular, separators proportional', () {
    final style = QType.countdown;
    double cell(String ch) => _width(ch, QType.countdownDigit(style, ch));
    // Tabular digits: "1" as wide as "0", so a ticking countdown is still.
    expect(cell('1'), closeTo(cell('0'), 0.01));
    // The colon is narrower than a digit cell.
    expect(cell(':'), lessThan(cell('0') * 0.7));
  });
}
