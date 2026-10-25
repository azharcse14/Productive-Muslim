/// Arabic reduced to bare letters (no harakat, Qur'anic marks, tatweel or
/// punctuation; alef/ya/ta-marbuta variants unified), so the same passage
/// compares equal however it was vocalised.
String bareArabic(String s) => s
    .replaceAll(RegExp('[ً-ٰٟۖ-ۭـ]'), '')
    .replaceAll(RegExp('[^ء-ي]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه');
