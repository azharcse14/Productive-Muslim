import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/utils/locale_digits.dart';

/// Spending buckets framed by Islamic priorities: needs first, then family,
/// then sadaqah, with wants kept in check (no israf — Al-A'raf 7:31).
enum ExpenseCategory { need, family, sadaqah, want }

final class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  });

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'] as int,
    amount: j['amount'] as int,
    category: ExpenseCategory.values.byName(j['category'] as String),
    date: DateTime.parse(j['date'] as String),
    note: j['note'] as String? ?? '',
  );

  final int id;

  /// Whole currency units (taka) — avoids float rounding in totals.
  final int amount;
  final ExpenseCategory category;
  final DateTime date;
  final String note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'category': category.name,
    'date': date.toIso8601String(),
    'note': note,
  };
}

/// Personal expense log (hisab). Persisted as one JSON string, mirroring
/// [FastingStore]'s prefs persistence.
final class ExpenseStore {
  ExpenseStore(
    this._prefs, {
    DateTime Function()? now,
    Future<void> Function(DateTime date)? onSadaqah,
  }) : _now = now ?? DateTime.now,
       _onSadaqah = onSadaqah;

  static const _key = 'expenses_v1';

  /// Records (or a whole payload) that couldn't be read, kept as a JSON list
  /// of raw strings so a save — which drops them from [_key] — never
  /// destroys the only copy. Every load retries them, so records written by
  /// a newer version come back after upgrading again.
  static const _unreadableKey = 'expenses_v1_unreadable_records';
  static const _budgetKey = 'expense_budget_v1';
  static const _categoryBudgetKey = 'expense_category_budgets_v1';

  final SharedPreferencesAsync _prefs;
  final DateTime Function() _now;

  /// Called with the date of each sadaqah added or edited — marks that
  /// day's muhasaba sadaqah done. Never unmarks (it may be ticked by hand).
  final Future<void> Function(DateTime date)? _onSadaqah;

  /// Newest first.
  late final entries = signal(const <Expense>[]);
  late final loaded = signal(false);

  /// Monthly spending limit (same for every month); null = no budget.
  late final budget = signal<int?>(null);

  /// Per-category monthly limits (for sadaqah, a goal); absent = none.
  late final categoryBudgets = signal(const <ExpenseCategory, int>{});

  /// Largest accepted amount — keeps int totals far from overflow.
  static const maxAmount = 999999999999;

  /// Whole-unit amount from user text (Bengali/Arabic digits and ','
  /// grouping accepted); null unless 1..[maxAmount].
  static int? parseAmount(String text) {
    final v = int.tryParse(LocaleDigits.toAscii(text.trim()), radix: 10);
    return v == null || v <= 0 || v > maxAmount ? null : v;
  }

  /// "Now" on the app's clock (the location's wall clock when injected).
  DateTime now() => _now();

  Future<void>? _loading;

  /// Loads once per store; every mutation awaits it first, so a write can
  /// never land before (and be clobbered by, or clobber) the stored list.
  /// A failed load is forgotten, so the next call (or write) retries it.
  Future<void> load() => _loading ??= () async {
    try {
      await _load();
    } on Object {
      _loading = null;
      rethrow;
    }
  }();

  Future<void> _load() async {
    final stored = await _prefs.getString(_key);
    final unreadable = <String>[
      for (final r in _decodeList(await _prefs.getString(_unreadableKey)))
        if (r is String) r,
    ];
    final before = unreadable.length;
    final read = <Expense>[];
    if (stored != null) {
      try {
        for (final j in jsonDecode(stored) as List) {
          try {
            read.add(Expense.fromJson(j as Map<String, dynamic>));
          } on Object {
            // One bad record (e.g. a category from a newer version).
            final raw = jsonEncode(j);
            if (!unreadable.contains(raw)) {
              unreadable.add(raw);
            }
          }
        }
      } on Object {
        if (!unreadable.contains(stored)) {
          unreadable.add(stored); // whole payload unreadable
        }
      }
    }
    // Retry the kept records; any that read now rejoin the list.
    final recovered = <Expense>[];
    for (final raw in [...unreadable]) {
      try {
        recovered.add(
          Expense.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
        unreadable.remove(raw);
      } on Object {
        // Still unreadable — keep it.
      }
    }
    entries.value = _persisted = read;
    if (recovered.isNotEmpty) {
      var list = read;
      for (final e in recovered) {
        // Already back under another id (a retried load whose earlier
        // attempt saved it but failed to shorten the unreadable list).
        if (!list.any((x) => _fields(x) == _fields(e))) {
          list = _withEntry(list, e);
        }
      }
      await _save(list);
    }
    // Only after the recovered records are saved: shortening this list
    // first would lose them if that save failed.
    if (unreadable.length != before || recovered.isNotEmpty) {
      await _prefs.setString(_unreadableKey, jsonEncode(unreadable));
    }
    budget.value = await _prefs.getInt(_budgetKey);
    final storedBudgets = await _prefs.getString(_categoryBudgetKey);
    if (storedBudgets != null) {
      try {
        categoryBudgets.value = {
          for (final MapEntry(:key, :value)
              in (jsonDecode(storedBudgets) as Map<String, dynamic>).entries)
            ExpenseCategory.values.byName(key): value as int,
        };
      } on Object {
        // Corrupt payload: no category budgets rather than a crash.
      }
    }
    loaded.value = true;
  }

  /// Sets the monthly budget; null or non-positive clears it.
  Future<void> setBudget(int? value) async {
    await load();
    if (value == null || value <= 0) {
      budget.value = null;
      await _prefs.remove(_budgetKey);
    } else {
      budget.value = value;
      await _prefs.setInt(_budgetKey, value);
    }
  }

  /// Adds an expense dated [date] (defaults to now). Non-positive amounts
  /// are ignored.
  Future<void> add({
    required int amount,
    required ExpenseCategory category,
    String note = '',
    DateTime? date,
  }) async {
    await load();
    if (amount <= 0 || amount > maxAmount) {
      return;
    }
    final e = Expense(
      id: entries.value.fold(0, (m, e) => e.id > m ? e.id : m) + 1,
      amount: amount,
      category: category,
      date: date ?? _now(),
      note: note.trim(),
    );
    final next = [e, ...entries.value]
      ..sort((a, b) => b.date.compareTo(a.date));
    await _save(next);
    await _markSadaqah(e);
  }

  /// Best-effort: the expense is already saved, so a hook failure must not
  /// surface as a failed save (a retry would add a duplicate).
  Future<void> _markSadaqah(Expense e) async {
    if (e.category == ExpenseCategory.sadaqah) {
      try {
        await _onSadaqah?.call(e.date);
      } on Object {
        // Muhasaba tick missed; the user can still tick it by hand.
      }
    }
  }

  /// Sets [category]'s monthly budget; null or non-positive clears it.
  Future<void> setCategoryBudget(ExpenseCategory category, int? value) async {
    await load();
    final next = Map.of(categoryBudgets.value)..remove(category);
    if (value != null && value > 0) {
      next[category] = value;
    }
    categoryBudgets.value = next;
    await _prefs.setString(
      _categoryBudgetKey,
      jsonEncode({for (final e in next.entries) e.key.name: e.value}),
    );
  }

  /// Replaces the entry with [id]'s fields (amount, category, note, date).
  /// Non-positive amounts are ignored.
  Future<void> update(
    int id, {
    required int amount,
    required ExpenseCategory category,
    required DateTime date,
    String note = '',
  }) async {
    await load();
    if (amount <= 0 || amount > maxAmount) {
      return;
    }
    final old = entries.value.where((e) => e.id == id).firstOrNull;
    if (old == null) {
      return; // removed elsewhere while being edited
    }
    final edited = Expense(
      id: id,
      amount: amount,
      category: category,
      date: date,
      note: note.trim(),
    );
    final next = [for (final e in entries.value) e.id == id ? edited : e]
      ..sort((a, b) => b.date.compareTo(a.date));
    await _save(next);
    // Only when it newly became a sadaqah or its date changed — re-saving must not
    // re-tick a day the user unticked by hand.
    if (old.category != category || old.date != date) {
      await _markSadaqah(edited);
    }
  }

  Future<void> remove(int id) async {
    await load();
    await _save([
      for (final e in entries.value)
        if (e.id != id) e,
    ]);
  }

  /// Puts a removed [expense] back (undo). Same fields; a fresh id only if
  /// a later add has taken its old one; a no-op if it's still there (the
  /// remove failed).
  Future<void> restore(Expense expense) async {
    await load();
    await _save(_withEntry(entries.value, expense));
  }

  /// [list] plus [e], re-ided when another entry holds its id, newest
  /// first; [list] itself when an identical entry is already there.
  static List<Expense> _withEntry(List<Expense> list, Expense e) {
    final holder = list.where((x) => x.id == e.id).firstOrNull;
    if (holder != null && _fields(holder) == _fields(e)) {
      return list;
    }
    final taken = holder != null;
    final entry = taken
        ? Expense(
            id: list.fold(0, (m, x) => x.id > m ? x.id : m) + 1,
            amount: e.amount,
            category: e.category,
            date: e.date,
            note: e.note,
          )
        : e;
    return [entry, ...list]..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Everything but the id.
  static String _fields(Expense e) => jsonEncode(e.toJson()..remove('id'));

  static List<Object?> _decodeList(String? raw) {
    if (raw == null) {
      return const [];
    }
    try {
      return jsonDecode(raw) as List<Object?>;
    } on Object {
      return const [];
    }
  }

  /// What [_key] holds after the last successful write.
  var _persisted = const <Expense>[];
  Future<void> _lastWrite = Future.value();

  /// Shows [next] at once (a swiped-away row must leave the tree now) and
  /// writes it after any earlier write. On failure, rolls back to what's
  /// stored and throws — unless a later change (built on this one) is
  /// already showing: then this change is saved iff a later write is, so
  /// it throws only if they all fail.
  Future<void> _save(List<Expense> next) async {
    entries.value = next;
    final write = _lastWrite
        .catchError((Object _) => false)
        .then(
          (_) => _prefs.setString(
            _key,
            jsonEncode([for (final e in next) e.toJson()]),
          ),
        );
    _lastWrite = write;
    try {
      await write;
      _persisted = next;
    } on Object {
      if (identical(entries.value, next)) {
        entries.value = _persisted;
        rethrow;
      }
      var settled = write;
      while (!identical(_lastWrite, settled)) {
        settled = _lastWrite;
        try {
          await settled;
          return; // saved along with the later change
        } on Object {
          // That one failed too (and rolled back); a newer one may follow.
        }
      }
      rethrow;
    }
  }

  /// First day of the month [offset] months from the current one.
  DateTime month([int offset = 0]) {
    final n = _now();
    return DateTime(n.year, n.month + offset);
  }

  List<Expense> inMonth(DateTime month) => [
    for (final e in entries.value)
      if (e.date.year == month.year && e.date.month == month.month) e,
  ];

  /// Per-category totals for [month]; every category present (0 if none).
  Map<ExpenseCategory, int> totalsFor(DateTime month) {
    final totals = {for (final c in ExpenseCategory.values) c: 0};
    for (final e in inMonth(month)) {
      totals[e.category] = totals[e.category]! + e.amount;
    }
    return totals;
  }

  static const _csvHeader = 'date,category,amount,note';

  /// All entries as CSV (oldest first) — opens in any spreadsheet and is
  /// the backup format [importCsv] reads back. Budgets are not included.
  Future<String> toCsv() async {
    await load();
    String quote(String v) => '"${v.replaceAll('"', '""')}"';
    return [
      _csvHeader,
      for (final e in entries.value.reversed)
        '${e.date.toIso8601String()},${e.category.name},${e.amount},'
            '${quote(e.note)}',
    ].join('\n');
  }

  /// Merges entries from [csv] (as written by [toCsv]), skipping ones
  /// already present, so re-importing the same backup is a no-op. Returns
  /// how many were added, or null if [csv] isn't a valid backup (nothing
  /// is imported then).
  Future<int?> importCsv(String csv) async {
    await load();
    final rows = [
      // Spreadsheets often leave blank lines or empty rows (",,,").
      for (final r in _parseCsv(csv.trim()))
        if (r.any((f) => f.trim().isNotEmpty)) r,
    ];
    if (rows.isEmpty ||
        rows.first.map((f) => f.trim().toLowerCase()).join(',') != _csvHeader) {
      return null;
    }
    final parsed = <Expense>[];
    for (final r in rows.skip(1)) {
      if (r.length != 4) {
        return null;
      }
      final date = DateTime.tryParse(r[0].trim());
      final category = ExpenseCategory.values.asNameMap()[r[1].trim()];
      final amount = parseAmount(r[2]);
      // toCsv writes wall-clock times; a UTC one would land on the wrong
      // day (and never match its local twin when deduping).
      if (date == null || date.isUtc || category == null || amount == null) {
        return null;
      }
      parsed.add(
        Expense(
          id: 0,
          amount: amount,
          category: category,
          date: date,
          note: r[3],
        ),
      );
    }
    String sig(Expense e) =>
        '${e.date.toIso8601String()}|${e.category.name}|${e.amount}|${e.note}';
    // Counted, not a set: two identical real entries both survive, while
    // re-importing the same backup still adds nothing.
    final have = <String, int>{};
    for (final e in entries.value) {
      have.update(sig(e), (n) => n + 1, ifAbsent: () => 1);
    }
    bool isNew(Expense e) {
      final n = have[sig(e)] ?? 0;
      have[sig(e)] = n - 1;
      return n <= 0;
    }

    var nextId = entries.value.fold(0, (m, e) => e.id > m ? e.id : m);
    final added = [
      for (final e in parsed)
        if (isNew(e))
          Expense(
            id: ++nextId,
            amount: e.amount,
            category: e.category,
            date: e.date,
            note: e.note,
          ),
    ];
    if (added.isNotEmpty) {
      await _save(
        [...entries.value, ...added]..sort((a, b) => b.date.compareTo(a.date)),
      );
    }
    return added.length;
  }

  /// Minimal RFC 4180 reader: quoted fields may hold commas, newlines and
  /// doubled quotes.
  static List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (quoted) {
        if (ch == '"' && i + 1 < input.length && input[i + 1] == '"') {
          field.write('"');
          i++;
        } else if (ch == '"') {
          quoted = false;
        } else {
          field.write(ch);
        }
      } else if (ch == '"') {
        quoted = true;
      } else if (ch == ',') {
        row.add(field.toString());
        field.clear();
      } else if (ch == '\n' || ch == '\r') {
        if (ch == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
          i++;
        }
        row.add(field.toString());
        field.clear();
        rows.add(row);
        row = <String>[];
      } else {
        field.write(ch);
      }
    }
    if (input.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }
}
