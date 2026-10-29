/// Fold applied to both the query and the searched text of every in-app
/// search: lowercase; Bengali য়/ড়/ঢ় (typed precomposed or as base + nukta,
/// depending on keyboard, and stored both ways in the bundled content)
/// folded to precomposed; ZWJ/ZWNJ dropped; Arabic harakat, Quranic marks
/// and tatweel dropped, alef forms unified and ى/ی→ي, ة→ه, ک→ك, so plain
/// typed Arabic (or a Persian/Urdu keyboard) matches vowelled text.
String foldForSearch(String input) {
  final lower = input
      .toLowerCase()
      .replaceAll('য়', 'য়')
      .replaceAll('ড়', 'ড়')
      .replaceAll('ঢ়', 'ঢ়');
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    if (rune == 0x200C ||
        rune == 0x200D ||
        (rune >= 0x064B && rune <= 0x065F) ||
        (rune >= 0x06D6 && rune <= 0x06ED) ||
        rune == 0x0670 ||
        rune == 0x0640) {
      continue;
    }
    buffer.writeCharCode(switch (rune) {
      0x0622 || 0x0623 || 0x0625 || 0x0671 => 0x0627, // alef forms → ا
      0x0649 || 0x06CC => 0x064A, // alef maksura, Persian yeh → ي
      0x0629 => 0x0647, // ta marbuta → ه
      0x06A9 => 0x0643, // Persian keheh → ك
      _ => rune,
    });
  }
  return buffer.toString();
}
