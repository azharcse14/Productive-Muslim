import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/utils/locale_digits.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/wall_time.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

export '../../domain/entities/expense.dart';

/// Personal expense log (hisab), persisted through [ExpenseRepository].
final class ExpenseStore {
  ExpenseStore(
    this._repo, {
    DateTime Function()? now,
    Future<void> Function(DateTime date)? onSadaqah,
    Locale Function()? deviceLocale,
  }) : _now = now ?? DateTime.now,
       _onSadaqah = onSadaqah,
       _deviceLocale =
           deviceLocale ?? (() => PlatformDispatcher.instance.locale);

  /// The device's locale (region included), for the default currency.
  final Locale Function() _deviceLocale;

  final ExpenseRepository _repo;
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

  /// ISO 4217 code of the expense amounts; null until [ensureCurrency]
  /// stores the default.
  late final currency = signal<String?>(null);

  /// Offered in the currency picker (any stored code still displays).
  static const commonCurrencies = [
    'BDT', 'USD', 'EUR', 'GBP', 'SAR', 'AED', 'INR', 'PKR', 'MYR', 'IDR', //
    'TRY', 'CAD', 'AUD',
  ];

  /// Device region → currency, for the picker's currencies.
  static const _regionCurrency = {
    'BD': 'BDT', 'US': 'USD', 'GB': 'GBP', 'SA': 'SAR', 'AE': 'AED', //
    'IN': 'INR', 'PK': 'PKR', 'MY': 'MYR', 'ID': 'IDR', 'TR': 'TRY',
    'CA': 'CAD', 'AU': 'AUD', 'DE': 'EUR', 'FR': 'EUR', 'IT': 'EUR',
    'ES': 'EUR', 'NL': 'EUR', 'BE': 'EUR', 'AT': 'EUR', 'IE': 'EUR',
    'PT': 'EUR', 'FI': 'EUR', 'GR': 'EUR',
  };

  /// Default currency: the device region's, else BDT for a Bangla app,
  /// else what `intl` maps the device locale to, else USD.
  static String currencyFor(Locale device, String appLanguage) {
    if (_regionCurrency[device.countryCode?.toUpperCase()] case final c?) {
      return c;
    }
    if (appLanguage == 'bn' || device.languageCode == 'bn') {
      return 'BDT';
    }
    try {
      return NumberFormat.simpleCurrency(
            locale: device.toLanguageTag(),
          ).currencyName ??
          'USD';
    } on ArgumentError {
      return 'USD';
    }
  }

  /// Stores the default currency once, so the symbol on stored amounts
  /// never changes with the device or app language: [currencyFor]. (With
  /// pre-decimal data, [load] already set BDT.) Best-effort: an unsaved
  /// default still shows and is retried next time.
  Future<void> ensureCurrency(String appLanguage) async {
    await load();
    if (currency.value != null) {
      return;
    }
    final code = currencyFor(_deviceLocale(), appLanguage);
    currency.value = code;
    try {
      _unwrap(await _repo.setCurrency(code));
    } on Object catch (e) {
      debugPrint('Expense currency not saved: $e');
    }
  }

  /// [minor] as [currencyCode] money in [languageCode]'s digits, always
  /// with 2 decimals (the stored precision) so amounts line up.
  static String formatAmount(
    int minor,
    String currencyCode,
    String languageCode,
  ) {
    final f = NumberFormat.simpleCurrency(
      locale: languageCode,
      name: currencyCode,
      decimalDigits: 2,
    );
    return LocaleDigits.localize(f.format(minor / 100), languageCode);
  }

  /// Plain editable text for [minor] (ASCII digits, '.' decimal, no
  /// grouping): 1250 → "12.50", 1200 → "12". Also the CSV amount format.
  static String amountText(int minor) {
    final whole = minor ~/ 100;
    final cents = minor % 100;
    return cents == 0 ? '$whole' : '$whole.${'$cents'.padLeft(2, '0')}';
  }

  /// Largest accepted amount in minor units (999,999,999,999.99) — keeps
  /// int totals far from overflow.
  static const maxAmount = 99999999999999;

  static final _amountPattern = RegExp(r'^(\d*)(?:\.(\d{0,2}))?$');

  /// Minor-unit amount from user text: up to 2 decimals after '.' or a
  /// decimal comma, Bengali/Arabic digits and grouping accepted (rules in
  /// [LocaleDigits.toAscii]); null unless 0.01..[maxAmount].
  static int? parseAmount(String text) {
    final m = _amountPattern.firstMatch(LocaleDigits.toAscii(text.trim()));
    if (m == null) {
      return null;
    }
    final whole = m[1]!;
    final cents = (m[2] ?? '').padRight(2, '0');
    // 15 digits overflow nothing and are already past maxAmount.
    if (whole.length > 15 || (whole.isEmpty && cents == '00')) {
      return null;
    }
    final v = int.parse(whole.isEmpty ? '0' : whole) * 100 + int.parse(cents);
    return v <= 0 || v > maxAmount ? null : v;
  }

  /// "Now" on the app's clock (the location's wall clock when injected).
  DateTime now() => _now();

  Future<void>? _loading;

  /// Highest id handed out or stored (hidden rows too). Never goes back, so
  /// a new id can't replace a stored row or one a failed write left behind.
  int _lastId = 0;

  int _newId() => ++_lastId;

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
    final data = _unwrap(await _repo.load());
    _lastId = data.maxId;
    entries.value = data.expenses; // newest first
    budget.value = data.budget;
    categoryBudgets.value = data.categoryBudgets;
    currency.value = data.currency;
    loaded.value = true;
  }

  static int _newestFirst(Expense a, Expense b) => b.date.compareTo(a.date);

  /// [r]'s value, or its failure thrown (screens show a save error).
  static T _unwrap<T>(Result<T> r) => switch (r) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw StateError(failure.message),
  };

  /// Persists the expense currency (an ISO 4217 code).
  Future<void> setCurrency(String code) async {
    await load();
    final previous = currency.value;
    currency.value = code;
    try {
      _unwrap(await _repo.setCurrency(code));
    } on Object {
      currency.value = previous;
      rethrow;
    }
  }

  /// Sets the monthly budget; null or non-positive clears it.
  Future<void> setBudget(int? value) async {
    await load();
    final previous = budget.value;
    final next = value == null || value <= 0 ? null : value;
    budget.value = next;
    try {
      _unwrap(await _repo.setBudget(next));
    } on Object {
      budget.value = previous; // not saved: don't show it as set
      rethrow; // the dialog tells the user
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
      id: _newId(),
      amount: amount,
      category: category,
      date: (date ?? _now()).floating,
      note: note.trim(),
    );
    await _write(
      [e, ...entries.value]..sort(_newestFirst),
      () => _repo.save([e]),
      // Only if still as added: an edit saved meanwhile is in the DB too.
      undo: (list) => [
        for (final x in list)
          if (x.id != e.id || x.fields != e.fields) x,
      ],
    );
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
    final previous = categoryBudgets.value;
    categoryBudgets.value = next;
    try {
      _unwrap(await _repo.setCategoryBudget(category, next[category]));
    } on Object {
      categoryBudgets.value = previous; // not saved: don't show it as set
      rethrow; // the dialog tells the user
    }
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
      date: date.floating,
      note: note.trim(),
    );
    List<Expense> put(List<Expense> list, Expense e) =>
        [for (final x in list) x.id == id ? e : x]..sort(_newestFirst);
    await _write(
      put(entries.value, edited),
      () => _repo.save([edited]),
      undo: (list) => put(list, old),
    );
    // Only when it newly became a sadaqah or moved to another day — re-saving
    // (even re-picking the same day) must not re-tick a day the user
    // unticked by hand.
    if (old.category != category ||
        old.date.wallDay(0) != edited.date.wallDay(0)) {
      await _markSadaqah(edited);
    }
  }

  Future<void> remove(int id) async {
    await load();
    final old = entries.value.where((e) => e.id == id).firstOrNull;
    if (old == null) {
      return;
    }
    await _write(
      [
        for (final e in entries.value)
          if (e.id != id) e,
      ],
      () => _repo.delete(id),
      undo: (list) => [old, ...list]..sort(_newestFirst),
    );
  }

  /// Puts a removed [expense] back (undo). Same fields; a fresh id only if
  /// a later add has taken its old one; a no-op if it's still there (the
  /// remove failed).
  Future<void> restore(Expense expense) async {
    await load();
    final next = _withEntry(entries.value, expense, _newId);
    if (identical(next, entries.value)) {
      return;
    }
    final e = next.firstWhere((x) => !entries.value.contains(x));
    await _write(
      next,
      () => _repo.save([e]),
      // Only if still as restored: an edit saved meanwhile is in the DB too.
      undo: (list) => [
        for (final x in list)
          if (x.id != e.id || x.fields != e.fields) x,
      ],
    );
  }

  /// [list] plus [e], re-ided when another entry holds its id, newest
  /// first; [list] itself when an identical entry is already there.
  static List<Expense> _withEntry(
    List<Expense> list,
    Expense e,
    int Function() newId,
  ) {
    final holder = list.where((x) => x.id == e.id).firstOrNull;
    if (holder != null && holder.fields == e.fields) {
      return list;
    }
    final entry = holder != null ? e.withId(newId()) : e;
    return [entry, ...list]..sort(_newestFirst);
  }

  /// Shows [next] at once (a swiped-away row must leave the tree now), then
  /// runs [persist]. On failure, [undo] takes this change back out of
  /// whatever is showing by then (later changes stay) and the error is
  /// rethrown.
  Future<void> _write(
    List<Expense> next,
    Future<Result<void>> Function() persist, {
    required List<Expense> Function(List<Expense> list) undo,
  }) async {
    entries.value = next;
    try {
      _unwrap(await persist());
    } on Object {
      entries.value = undo(entries.value);
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

  /// What counts as spending (budget, month-over-month): everything but
  /// sadaqah — giving more must never read as overspending.
  static int spendingOf(Iterable<Expense> list) => list
      .where((e) => e.category != ExpenseCategory.sadaqah)
      .fold(0, (a, e) => a + e.amount);

  static const _csvHeader = 'date,category,amount,note';
  // Leading quotes count too, so a note like '=x round-trips. Tab and CR
  // also start formulas in some spreadsheets (OWASP CSV injection).
  static final _formulaStart = RegExp(r"^'*[=+\-@\t\r]");
  static final _escapedFormula = RegExp(r"^''*[=+\-@\t\r]");

  /// All entries as CSV (oldest first) — opens in any spreadsheet and is
  /// the backup format [importCsv] reads back. Budgets are not included.
  ///
  /// The amount column is always in major units with a '.' decimal
  /// ("12.50", "120") — so a pre-decimal backup's whole numbers ("120")
  /// read back as the same 120.00, and no version column is needed.
  Future<String> toCsv() async {
    await load();
    // A leading ' stops spreadsheets running =,+,-,@ notes as formulas;
    // importCsv strips it again.
    String quote(String v) =>
        '"${_formulaStart.hasMatch(v) ? "'" : ''}${v.replaceAll('"', '""')}"';
    return [
      _csvHeader,
      for (final e in entries.value.reversed)
        '${e.date.toIso8601String()},${e.category.name},'
            '${amountText(e.amount)},'
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
      // Wall-clock fields, floating: older backups wrote them device-local.
      final date = DateTime.tryParse(r[0].trim())?.floating;
      final category = ExpenseCategory.values.asNameMap()[r[1].trim()];
      final amount = parseAmount(r[2]);
      if (date == null || category == null || amount == null) {
        return null;
      }
      parsed.add(
        Expense(
          id: 0,
          amount: amount,
          category: category,
          date: date,
          note: _escapedFormula.hasMatch(r[3]) ? r[3].substring(1) : r[3],
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

    final added = [
      for (final e in parsed)
        if (isNew(e)) e.withId(_newId()),
    ];
    if (added.isNotEmpty) {
      final fields = {for (final e in added) e.id: e.fields};
      await _write(
        [...entries.value, ...added]..sort(_newestFirst),
        () => _repo.save(added),
        // Only rows still as imported: an edit saved meanwhile is stored.
        undo: (list) => [
          for (final x in list)
            if (fields[x.id] != x.fields) x,
        ],
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
