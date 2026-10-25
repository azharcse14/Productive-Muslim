/// ﷺ is reserved for the Prophet Muhammad: every occurrence must directly
/// follow a word naming him. Returns the offending snippets found in any
/// string inside [json] (a decoded asset).
List<String> misplacedSalawat(Object? json) {
  const stems = [
    'prophet', 'messenger', 'muhammad', 'muḥammad', //
    'নবী', 'নাবি', 'রাসূল', 'মুহাম্মাদ', 'মুহাম্মদ',
  ];
  final bad = <String>[];
  void walk(Object? o) {
    switch (o) {
      case final Map<Object?, Object?> m:
        m.values.forEach(walk);
      case final List<Object?> l:
        l.forEach(walk);
      case final String s:
        for (final m in 'ﷺ'.allMatches(s)) {
          final before = s
              .substring(0, m.start)
              .replaceAll(RegExp("[()'’ʼ]"), '')
              .trim()
              .toLowerCase();
          final word = before.split(RegExp(r'\s+')).last;
          if (!stems.any(word.contains)) {
            bad.add(s.substring(m.start < 40 ? 0 : m.start - 40, m.end));
          }
        }
    }
  }

  walk(json);
  return bad;
}
