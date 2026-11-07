import 'package:flutter/painting.dart';

import '../../config/assets.dart';

/// Arabic punctuation UthmanicHafs maps to a dotted circle: ، ؛ ؟ ٪ ٫ ٬ ٭ ۔
/// (checked glyph-by-glyph against the font). `fontFamilyFallback` can't help
/// because the glyph exists.
final _dottedInHafs = RegExp('[،؛؟٪-٭۔]+');

/// [text] in [style] (the Hafs font), with every character in
/// [_dottedInHafs] drawn in the UI Arabic font instead.
/// For dua, ruqyah and hadith Arabic — Quran text has none of them.
TextSpan hafsSpan(String text, TextStyle style) {
  if (!_dottedInHafs.hasMatch(text)) return TextSpan(text: text, style: style);
  final uiStyle = style.copyWith(fontFamily: AppFonts.arabicUi);
  final children = <InlineSpan>[];
  var start = 0;
  for (final m in _dottedInHafs.allMatches(text)) {
    if (m.start > start) {
      children.add(TextSpan(text: text.substring(start, m.start)));
    }
    children.add(TextSpan(text: m[0], style: uiStyle));
    start = m.end;
  }
  if (start < text.length) children.add(TextSpan(text: text.substring(start)));
  return TextSpan(style: style, children: children);
}
