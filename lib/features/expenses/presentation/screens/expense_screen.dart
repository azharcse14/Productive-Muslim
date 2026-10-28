import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_chip.dart';
import '../state/expense_store.dart';

const _icons = {
  ExpenseCategory.need: Icons.home_outlined,
  ExpenseCategory.family: Icons.family_restroom_outlined,
  ExpenseCategory.sadaqah: Icons.volunteer_activism_outlined,
  ExpenseCategory.want: Icons.shopping_bag_outlined,
};

/// Islamic expense tracker: a monthly hisab by category, an israf reminder,
/// and the month's entries (swipe or edit → Delete, with undo).
final class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

final class _ExpenseScreenState extends State<ExpenseScreen> {
  // App-scoped store — never disposed here.
  late final ExpenseStore _store = locator<ExpenseStore>();

  /// 0 = current month, -1 = previous, …
  int _offset = 0;

  /// Category the entry list is narrowed to; null shows all.
  ExpenseCategory? _filter;

  /// Bumped per swipe-delete of that row; part of its key.
  final _dismissals = <int, int>{};

  @override
  void initState() {
    super.initState();
    if (!_store.loaded.value) {
      // A failure is retried by the next load or write; nothing to show yet.
      unawaited(_store.load().catchError((Object _) {}));
    }
  }

  // ponytail: clipboard as transport — swap for a share sheet / file once
  // share_plus (or similar) is a dependency.
  Future<void> _export() async {
    await Clipboard.setData(ClipboardData(text: await _store.toCsv()));
    if (mounted) {
      _snack(context.l10n.expenseExported);
    }
  }

  Future<void> _import() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    final added = text == null ? null : await _store.importCsv(text);
    if (mounted) {
      _snack(
        added == null
            ? context.l10n.expenseImportInvalid
            : context.l10n.expenseImported(added),
      );
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final code = Localizations.localeOf(context).languageCode;
    String n(int v) => LocaleDigits.localize(
      NumberFormat.decimalPattern(code).format(v),
      code,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.expenseTitle),
        actions: [
          IconButton(
            tooltip: l10n.expenseBudget,
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => _showBudgetDialog(
              context,
              title: l10n.expenseBudget,
              current: _store.budget.value,
              onSave: _store.setBudget,
            ),
          ),
          PopupMenuButton<bool>(
            tooltip: l10n.expenseBackup,
            onSelected: (export) => export ? _export() : _import(),
            itemBuilder: (_) => [
              PopupMenuItem(value: true, child: Text(l10n.expenseExportCsv)),
              PopupMenuItem(value: false, child: Text(l10n.expenseImportCsv)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.expenseAdd,
        onPressed: () => _showExpenseSheet(context, _store),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            _store.entries.value;
            final budget = _store.budget.value;
            final categoryBudgets = _store.categoryBudgets.value;
            final month = _store.month(_offset);
            // One pass: category totals, the shown entries, per-day sums.
            final totals = {for (final c in ExpenseCategory.values) c: 0};
            final items = <Expense>[];
            final dayTotals = <DateTime, int>{};
            for (final e in _store.inMonth(month)) {
              totals[e.category] = totals[e.category]! + e.amount;
              if (_filter == null || e.category == _filter) {
                items.add(e);
                final day = DateUtils.dateOnly(e.date);
                dayTotals[day] = (dayTotals[day] ?? 0) + e.amount;
              }
            }
            final total = totals.values.fold(0, (a, b) => a + b);
            // The current month is partial: compare against the same span of
            // last month, not all of it.
            final now = _store.now();
            final soFar = _offset == 0;
            final prev = _store
                .inMonth(_store.month(_offset - 1))
                .where((e) => !soFar || e.date.day <= now.day)
                .fold(0, (a, e) => a + e.amount);
            final diff = total - prev;
            // Calendar days, not 24h spans: a DST shift can't mislabel.
            final yesterday = DateTime(now.year, now.month, now.day - 1);
            String dayLabel(DateTime d) => DateUtils.isSameDay(d, now)
                ? l10n.periodToday
                : DateUtils.isSameDay(d, yesterday)
                ? l10n.expenseYesterday
                : LocaleDigits.localize(DateFormat.MMMEd(code).format(d), code);
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                QSpace.s5,
                QSpace.s3,
                QSpace.s5,
                96,
              ),
              children: [
                QCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: l10n.expensePrevMonth,
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => setState(() => _offset--),
                          ),
                          Expanded(
                            child: Text(
                              LocaleDigits.localize(
                                DateFormat.yMMMM(code).format(month),
                                code,
                              ),
                              textAlign: TextAlign.center,
                              style: QType.titleSm.copyWith(color: q.ink),
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.expenseNextMonth,
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _offset < 0
                                ? () => setState(() => _offset++)
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: QSpace.s2),
                      Text(
                        n(total),
                        style: QType.headline.copyWith(color: q.ink),
                      ),
                      Text(
                        l10n.expenseMonthTotal,
                        style: QType.caption.copyWith(color: q.ink2),
                      ),
                      if (prev > 0) ...[
                        const SizedBox(height: QSpace.s1),
                        Text(
                          (soFar
                              ? l10n.expenseVsLastMonthSoFar
                              : l10n.expenseVsLastMonth)(
                            diff > 0
                                ? 'more'
                                : diff < 0
                                ? 'less'
                                : 'same',
                            n(diff.abs()),
                          ),
                          style: QType.caption.copyWith(
                            color: diff > 0 ? q.urgent : q.ink2,
                          ),
                        ),
                      ],
                      if (budget != null) ...[
                        const SizedBox(height: QSpace.s3),
                        LinearProgressIndicator(
                          value: (total / budget).clamp(0, 1).toDouble(),
                          color: total > budget ? q.urgent : q.ok,
                          backgroundColor: q.line,
                        ),
                        const SizedBox(height: QSpace.s1),
                        Text(
                          total > budget
                              ? l10n.expenseBudgetOver(n(total - budget))
                              : l10n.expenseBudgetLeft(
                                  n(budget - total),
                                  n(budget),
                                ),
                          style: QType.caption.copyWith(
                            color: total > budget ? q.urgent : q.ink2,
                          ),
                        ),
                      ],
                      const SizedBox(height: QSpace.s4),
                      Text(
                        l10n.expenseCategoryBudgetHint,
                        style: QType.caption.copyWith(color: q.ink3),
                      ),
                      const SizedBox(height: QSpace.s2),
                      for (final c in ExpenseCategory.values)
                        _CategoryRow(
                          category: c,
                          spent: totals[c]!,
                          monthTotal: total,
                          budget: categoryBudgets[c],
                          format: n,
                          selected: _filter == c,
                          onTap: () =>
                              setState(() => _filter = _filter == c ? null : c),
                          onLongPress: () => _showBudgetDialog(
                            context,
                            title: l10n.expenseCategoryBudgetTitle(c.name),
                            current: categoryBudgets[c],
                            onSave: (v) => _store.setCategoryBudget(c, v),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: QSpace.s4),
                QBanner(
                  text: l10n.expenseIsrafReminder,
                  icon: Icons.format_quote_outlined,
                ),
                const SizedBox(height: QSpace.s4),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(QSpace.s5),
                    child: Text(
                      l10n.expenseEmpty,
                      textAlign: TextAlign.center,
                      style: QType.body.copyWith(color: q.ink2),
                    ),
                  ),
                for (final (i, e) in items.indexed) ...[
                  // Entries are newest first: a header opens each new day.
                  if (i == 0 || !DateUtils.isSameDay(items[i - 1].date, e.date))
                    Padding(
                      padding: const EdgeInsets.only(
                        top: QSpace.s3,
                        bottom: QSpace.s1,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              dayLabel(DateUtils.dateOnly(e.date)),
                              style: QType.label.copyWith(color: q.ink2),
                            ),
                          ),
                          Text(
                            n(dayTotals[DateUtils.dateOnly(e.date)]!),
                            style: QType.caption.copyWith(color: q.ink2),
                          ),
                        ],
                      ),
                    ),
                  Dismissible(
                    // A fresh key after its swipe: a row put back by a
                    // failed delete must not reuse the dismissed widget.
                    // Other rows keep theirs (a swipe may be mid-flight).
                    key: ValueKey((e.id, _dismissals[e.id] ?? 0)),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: AlignmentDirectional.centerEnd,
                      padding: const EdgeInsets.symmetric(
                        horizontal: QSpace.s4,
                      ),
                      color: q.urgentSoft,
                      child: Icon(Icons.delete_outline, color: q.urgent),
                    ),
                    onDismissed: (_) {
                      setState(
                        () => _dismissals.update(
                          e.id,
                          (n) => n + 1,
                          ifAbsent: () => 1,
                        ),
                      );
                      _removeWithUndo(context, _store, e);
                    },
                    child: ListTile(
                      onTap: () =>
                          _showExpenseSheet(context, _store, existing: e),
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_icons[e.category], color: q.ink2),
                      title: Text(
                        e.note.isEmpty
                            ? l10n.expenseCategory(e.category.name)
                            : e.note,
                      ),
                      // The day header has the date; a noted row names its
                      // category (an un-noted one already shows it).
                      subtitle: e.note.isEmpty
                          ? null
                          : Text(l10n.expenseCategory(e.category.name)),
                      trailing: Text(
                        n(e.amount),
                        style: QType.label.copyWith(color: q.ink),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Removes [e] and offers Undo (swipe and the editor's Delete both land
/// here, so a stray swipe is recoverable).
void _removeWithUndo(BuildContext context, ExpenseStore store, Expense e) {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  late final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> undo;
  var undoShowing = true;
  // Closes this row's Undo bar (never another row's): the entry is back.
  void failed(Object _) {
    if (undoShowing) {
      undo.close();
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.expenseSaveFailed)));
  }

  unawaited(store.remove(e.id).catchError(failed));
  // Removed, not hidden, so this bar is first in the queue at once —
  // close() above requires that.
  messenger.removeCurrentSnackBar();
  undo = messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.expenseDeleted),
      // An action makes it persist by default; Undo is only offered
      // briefly (it must not linger across screens).
      persist: false,
      action: SnackBarAction(
        label: l10n.expenseUndo,
        onPressed: () => unawaited(store.restore(e).catchError(failed)),
      ),
    ),
  );
  unawaited(undo.closed.then((_) => undoShowing = false));
}

/// Asks before an edited sheet is closed without saving.
Future<bool> _confirmDiscard(BuildContext context) async {
  final l10n = context.l10n;
  final discard = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.editorDiscardTitle),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.editorDiscard),
        ),
      ],
    ),
  );
  return discard ?? false;
}

void _showSaveFailed(BuildContext context) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(context.l10n.expenseSaveFailed)));

/// One category line: spent, and either its share of the month or, with a
/// budget, progress against it. Sadaqah's budget is a goal — exceeding it
/// is good, so it never turns red.
final class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.spent,
    required this.monthTotal,
    required this.budget,
    required this.format,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final ExpenseCategory category;
  final int spent;
  final int monthTotal;
  final int? budget;
  final String Function(int) format;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final b = budget;
    final isGoal = category == ExpenseCategory.sadaqah;
    final over = b != null && !isGoal && spent > b;
    return Semantics(
      selected: selected,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(QRadius.sm),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? q.primarySoft : null,
            borderRadius: BorderRadius.circular(QRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: QSpace.s2,
            vertical: QSpace.s2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_icons[category], size: 18, color: q.ink2),
                  const SizedBox(width: QSpace.s2),
                  Expanded(
                    child: Text(
                      l10n.expenseCategory(category.name),
                      style: QType.body.copyWith(color: q.ink),
                    ),
                  ),
                  Text(
                    b == null
                        ? format(spent)
                        : '${format(spent)} / ${format(b)}',
                    style: QType.label.copyWith(color: over ? q.urgent : q.ink),
                  ),
                ],
              ),
              const SizedBox(height: QSpace.s1),
              LinearProgressIndicator(
                value: b != null
                    ? (spent / b).clamp(0, 1).toDouble()
                    : monthTotal == 0
                    ? 0
                    : spent / monthTotal,
                color: over
                    ? q.urgent
                    : isGoal
                    ? q.accent
                    : q.primary,
                backgroundColor: q.line,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Number dialog for a budget: Save sets it, Remove (shown when one is
/// set) clears it.
Future<void> _showBudgetDialog(
  BuildContext context, {
  required String title,
  required int? current,
  required Future<void> Function(int?) onSave,
}) => showDialog<void>(
  context: context,
  builder: (_) => _BudgetDialog(title: title, current: current, onSave: onSave),
);

/// Owns its controller so it lives until the route (and its exit
/// animation) is gone — disposing on the dialog future's completion is
/// too early.
final class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({
    required this.title,
    required this.current,
    required this.onSave,
  });

  final String title;
  final int? current;
  final Future<void> Function(int?) onSave;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

final class _BudgetDialogState extends State<_BudgetDialog> {
  late final _controller = TextEditingController(
    text: widget.current == null
        ? ''
        : LocaleDigits.localize(
            '${widget.current}',
            Localizations.localeOf(context).languageCode,
          ),
  );

  /// Pops at once (optimistic); a failed write reverts in the store and is
  /// reported on the screen's messenger.
  void _save(int? value) {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.expenseSaveFailed;
    unawaited(
      widget
          .onSave(value)
          .catchError(
            (Object _) =>
                messenger.showSnackBar(SnackBar(content: Text(failed))),
          ),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = _controller.text.trim();
    final invalid = text.isNotEmpty && ExpenseStore.parseAmount(text) == null;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: l10n.expenseAmountHint,
          errorText: invalid ? l10n.expenseAmountInvalid : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        if (widget.current != null)
          TextButton(
            onPressed: () => _save(null),
            child: Text(l10n.expenseBudgetClear),
          ),
        TextButton(
          onPressed: () {
            final v = ExpenseStore.parseAmount(_controller.text);
            if (v != null) {
              _save(v);
            }
          },
          child: Text(l10n.expenseSave),
        ),
      ],
    );
  }
}

/// Add (no [existing]) or edit sheet: amount, note, category, date.
Future<void> _showExpenseSheet(
  BuildContext context,
  ExpenseStore store, {
  Expense? existing,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  // A drag can't be vetoed; back / outside taps confirm via PopScope.
  enableDrag: false,
  builder: (sheetContext) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
    ),
    child: _ExpenseEditor(store: store, existing: existing),
  ),
);

final class _ExpenseEditor extends StatefulWidget {
  const _ExpenseEditor({required this.store, this.existing});

  final ExpenseStore store;
  final Expense? existing;

  @override
  State<_ExpenseEditor> createState() => _ExpenseEditorState();
}

final class _ExpenseEditorState extends State<_ExpenseEditor> {
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : LocaleDigits.localize(
            '${widget.existing!.amount}',
            Localizations.localeOf(context).languageCode,
          ),
  );
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  late ExpenseCategory _category =
      widget.existing?.category ?? ExpenseCategory.need;
  late DateTime _date = widget.existing?.date ?? widget.store.now();

  /// Set while a save is in flight — a second tap must neither add again
  /// nor pop the screen under the closing sheet.
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int? get _parsed => ExpenseStore.parseAmount(_amount.text);

  /// Anything to lose if the sheet closes now.
  bool get _dirty {
    final e = widget.existing;
    if (e == null) {
      return _amount.text.trim().isNotEmpty || _note.text.trim().isNotEmpty;
    }
    return _parsed != e.amount ||
        _note.text != e.note ||
        _category != e.category ||
        _date != e.date;
  }

  /// Up to five past notes containing what's typed, most recent first; a
  /// pick also brings back that note's category.
  List<Expense> get _suggestions {
    final typed = _note.text.trim().toLowerCase();
    final seen = <String>{};
    return [
      for (final e in widget.store.entries.value)
        if (e.note.isNotEmpty &&
            e.note.toLowerCase() != typed &&
            e.note.toLowerCase().contains(typed) &&
            seen.add(e.note.toLowerCase()))
          e,
    ].take(5).toList();
  }

  Future<void> _pickDate() async {
    final now = widget.store.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      // Keep the time of day so same-day entries stay in entry order.
      setState(
        () => _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
          _date.second,
        ),
      );
    }
  }

  Future<void> _save() async {
    final amount = _parsed;
    if (_saving || amount == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.existing case final existing?) {
        await widget.store.update(
          existing.id,
          amount: amount,
          category: _category,
          note: _note.text,
          date: _date,
        );
      } else {
        await widget.store.add(
          amount: amount,
          category: _category,
          note: _note.text,
          date: _date,
        );
      }
    } on Object {
      // Not saved (the store rolled back): keep the sheet so they can retry.
      if (mounted) {
        setState(() => _saving = false);
        _showSaveFailed(context);
      }
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final code = Localizations.localeOf(context).languageCode;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        final navigator = Navigator.of(context);
        if (!didPop && await _confirmDiscard(context)) {
          navigator.pop();
        }
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(QSpace.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null ? l10n.expenseAdd : l10n.expenseEdit,
                style: QType.title.copyWith(color: q.ink),
              ),
              const SizedBox(height: QSpace.s4),
              TextField(
                controller: _amount,
                autofocus: widget.existing == null,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: l10n.expenseAmountHint,
                  errorText: _amount.text.trim().isNotEmpty && _parsed == null
                      ? l10n.expenseAmountInvalid
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: QSpace.s3),
              TextField(
                controller: _note,
                decoration: InputDecoration(hintText: l10n.expenseNoteHint),
                onChanged: (_) => setState(() {}),
              ),
              if (_suggestions case final picks when picks.isNotEmpty) ...[
                const SizedBox(height: QSpace.s2),
                Wrap(
                  spacing: QSpace.s2,
                  runSpacing: QSpace.s2,
                  children: [
                    for (final e in picks)
                      QChip(
                        label: e.note,
                        icon: Icons.history,
                        onTap: () => setState(() {
                          _note.text = e.note;
                          _category = e.category;
                        }),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: QSpace.s4),
              Wrap(
                spacing: QSpace.s2,
                runSpacing: QSpace.s2,
                children: [
                  for (final c in ExpenseCategory.values)
                    QChip(
                      label: l10n.expenseCategory(c.name),
                      icon: _icons[c],
                      active: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: QSpace.s4),
              QButton(
                label: LocaleDigits.localize(
                  DateFormat.yMMMd(code).format(_date),
                  code,
                ),
                icon: Icons.calendar_today_outlined,
                kind: QButtonKind.outline,
                small: true,
                onPressed: _pickDate,
              ),
              const SizedBox(height: QSpace.s5),
              QButton(
                label: l10n.expenseSave,
                expand: true,
                onPressed: !_saving && _parsed != null ? _save : null,
              ),
              if (widget.existing case final existing?) ...[
                const SizedBox(height: QSpace.s2),
                QButton(
                  label: l10n.delete,
                  icon: Icons.delete_outline,
                  kind: QButtonKind.outline,
                  expand: true,
                  onPressed: _saving
                      ? null
                      : () {
                          // Undo SnackBar lives on the screen's messenger.
                          _removeWithUndo(context, widget.store, existing);
                          Navigator.of(context).pop();
                        },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
