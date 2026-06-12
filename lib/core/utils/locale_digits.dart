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
}
