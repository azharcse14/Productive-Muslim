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

  @override
  void initState() {
    super.initState();
    if (!_store.loaded.value) {
      // A failure is retried by the next load or write; nothing to show yet.
      unawaited(_store.load().catchError((Object _) {}));
    }
  }

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
            icon: const Icon(Icons.savings_outlined),
            onPressed: () => _showBudgetDialog(
              context,
              title: l10n.expenseBudget,
              current: _store.budget.value,
              onSave: _store.setBudget,
            ),
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
            final totals = _store.totalsFor(month);
            final total = totals.values.fold(0, (a, b) => a + b);
            final items = _store.inMonth(month);
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
                          onTap: () => _showBudgetDialog(
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
                for (final e in items)
                  Dismissible(
                    key: ValueKey(e.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: AlignmentDirectional.centerEnd,
                      padding: const EdgeInsets.symmetric(
                        horizontal: QSpace.s4,
                      ),
                      color: q.urgentSoft,
                      child: Icon(Icons.delete_outline, color: q.urgent),
                    ),
                    onDismissed: (_) => _removeWithUndo(context, _store, e),
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
                      subtitle: Text(
                        LocaleDigits.localize(
                          DateFormat.MMMd(code).format(e.date),
                          code,
                        ),
                      ),
                      trailing: Text(
                        n(e.amount),
                        style: QType.label.copyWith(color: q.ink),
                      ),
                    ),
                  ),
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
  void failed(Object _) => messenger.showSnackBar(
    SnackBar(content: Text(l10n.expenseSaveFailed)),
  );
  unawaited(store.remove(e.id).catchError(failed));
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
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
}

void _showSaveFailed(BuildContext context) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.expenseSaveFailed)),
    );

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
    required this.onTap,
  });

  final ExpenseCategory category;
  final int spent;
  final int monthTotal;
  final int? budget;
  final String Function(int) format;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final b = budget;
    final isGoal = category == ExpenseCategory.sadaqah;
    final over = b != null && !isGoal && spent > b;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: QSpace.s2),
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
                  b == null ? format(spent) : '${format(spent)} / ${format(b)}',
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
  builder: (_) =>
      _BudgetDialog(title: title, current: current, onSave: onSave),
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
    text: widget.current?.toString() ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = _controller.text.trim();
    final invalid =
        text.isNotEmpty && ExpenseStore.parseAmount(text) == null;
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
            onPressed: () {
              unawaited(widget.onSave(null));
              Navigator.of(context).pop();
            },
            child: Text(l10n.expenseBudgetClear),
          ),
        TextButton(
          onPressed: () {
            final v = ExpenseStore.parseAmount(_controller.text);
            if (v != null) {
              unawaited(widget.onSave(v));
              Navigator.of(context).pop();
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
    text: widget.existing?.amount.toString() ?? '',
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
    unawaited(HapticFeedback.selectionClick());
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
    return SafeArea(
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
            ),
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
    );
  }
}
