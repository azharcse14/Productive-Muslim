/// Per-locale digit rendering (design: Western 123 / Bengali ১২৩ /
/// Eastern Arabic ١٢٣). Use for any user-facing number or time string.
abstract final class LocaleDigits {
  static const _bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  static const _easternArabic = [
    '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩', //
  ];

  /// Converts ASCII digits in [input] to the digit set of [languageCode].
  /// Unknown locales pass through unchanged (Western digits).
  static String localize(String input, String languageCode) {
    final digits = switch (languageCode) {
      'bn' => _bengali,
      'ar' || 'ur' => _easternArabic,
      _ => null,
    };
    if (digits == null) {
      return input;
    }
    final buffer = StringBuffer();
    for (final code in input.codeUnits) {
      if (code >= 0x30 && code <= 0x39) {
        buffer.write(digits[code - 0x30]);
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  /// Inverse of [localize] for parsing user input: maps Bengali (০-৯),
  /// Arabic-Indic (٠-٩) and Extended Arabic-Indic (۰-۹) digits to ASCII,
  /// the Arabic decimal separator (٫) to '.', and strips thousands
  /// separators ('٬' and whitespace). ',' is grouping when a '.' is present,
  /// it repeats, or 3 digits follow it ("1,000", "1,00,000"); otherwise it
  /// is a decimal comma ("12,5" from a European keypad). Feed the result to
  /// `double.tryParse` / `int.tryParse`.
  static String toAscii(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x09E6 && rune <= 0x09EF) {
        buffer.writeCharCode(0x30 + rune - 0x09E6);
      } else if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + rune - 0x06F0);
      } else if (rune == 0x066B) {
        buffer.write('.');
      } else if (rune == 0x066C || _isSpace(rune)) {
        continue;
      } else {
        buffer.writeCharCode(rune);
      }
    }
    final out = buffer.toString();
    final comma = out.indexOf(',');
    if (comma != -1 &&
        !out.contains('.') &&
        comma == out.lastIndexOf(',') &&
        !RegExp(r',\d{3}$').hasMatch(out)) {
      return out.replaceFirst(',', '.');
    }
    return out.replaceAll(',', '');
  }

  static bool _isSpace(int rune) => String.fromCharCode(rune).trim().isEmpty;
}
