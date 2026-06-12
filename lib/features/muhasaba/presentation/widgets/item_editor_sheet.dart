import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_seg_control.dart';
import '../../domain/entities/tracker_item.dart';
import '../state/muhasaba_store.dart';
import 'tracker_visuals.dart';

/// Custom-field creation/edit flow (design §4.7): name, type, optional
/// daily target, icon & color from curated sets, archive (never delete).
Future<void> showItemEditor(
  BuildContext context,
  MuhasabaStore store, {
  TrackerItem? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _ItemEditor(store: store, existing: existing),
    ),
  );
}

final class _ItemEditor extends StatefulWidget {
  const _ItemEditor({required this.store, this.existing});

  final MuhasabaStore store;
  final TrackerItem? existing;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

final class _ItemEditorState extends State<_ItemEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late TrackerKind _kind = widget.existing?.kind ?? TrackerKind.yesNo;
  late int? _target = widget.existing?.dailyTarget;
  late String _icon = widget.existing?.icon ?? 'spark';
  late int _colorIndex = widget.existing?.colorIndex ?? 0;

  bool get _isEdit => widget.existing != null;
  bool get _structuralLocked => widget.existing?.isDefault ?? false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty && !_isEdit) {
      return;
    }
    if (widget.existing case final existing?) {
      await widget.store.updateItem(
        existing.copyWith(
          name: name.isEmpty ? existing.name : name,
          kind: _structuralLocked ? null : _kind,
          dailyTarget: () => _target,
          icon: _icon,
          colorIndex: _colorIndex,
        ),
      );
    } else {
      await widget.store.addItem(
        name: name,
        kind: _kind,
        dailyTarget: _target,
        icon: _icon,
        colorIndex: _colorIndex,
      );
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _archive() async {
    final existing = widget.existing;
    if (existing == null) {
      return;
    }
    await widget.store.setArchived(existing.id, archived: !existing.archived);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(QSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit ? l10n.editTracker : l10n.addTracker,
              style: QType.title.copyWith(color: q.ink),
            ),
            const SizedBox(height: QSpace.s4),
            if (!_structuralLocked) ...[
              TextField(
                controller: _name,
                decoration: InputDecoration(hintText: l10n.trackerNameHint),
              ),
              const SizedBox(height: QSpace.s4),
              Text(l10n.trackerKindLabel, style: context.text.labelSmall),
              const SizedBox(height: QSpace.s2),
              QSegControl(
                options: [l10n.kindYesNo, l10n.kindCount, l10n.kindDuration],
                activeIndex: _kind.index,
                onChanged: (i) => setState(() {
                  _kind = TrackerKind.values[i];
                  if (_kind == TrackerKind.yesNo) {
                    _target = null;
                  }
                }),
              ),
              const SizedBox(height: QSpace.s4),
              if (_kind != TrackerKind.yesNo) ...[
                Text(l10n.targetLabel, style: context.text.labelSmall),
                const SizedBox(height: QSpace.s2),
                Row(
                  children: [
                    _TargetStepper(
                      value: _target,
                      step: _kind == TrackerKind.duration ? 5 : 1,
                      onChanged: (v) => setState(() => _target = v),
                    ),
                    const SizedBox(width: QSpace.s2),
                    Text(
                      _kind == TrackerKind.duration
                          ? l10n.targetMinutesSuffix
                          : l10n.targetCountSuffix,
                      style: QType.caption.copyWith(color: q.ink2),
                    ),
                  ],
                ),
                const SizedBox(height: QSpace.s4),
              ],
            ],
            Wrap(
              spacing: QSpace.s2,
              runSpacing: QSpace.s2,
              children: [
                for (final entry in TrackerVisuals.icons.entries)
                  _PickCircle(
                    selected: _icon == entry.key,
                    child: Icon(
                      entry.value,
                      size: 19,
                      color: _icon == entry.key ? q.onPrimary : q.ink2,
                    ),
                    onTap: () => setState(() => _icon = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: QSpace.s3),
            Wrap(
              spacing: QSpace.s2,
              children: [
                for (final (i, color)
                    in TrackerVisuals.palette(q).indexed)
                  _PickCircle(
                    selected: _colorIndex == i,
                    fill: color,
                    onTap: () => setState(() => _colorIndex = i),
                  ),
              ],
            ),
            const SizedBox(height: QSpace.s5),
            if (_isEdit) ...[
              QBanner(text: l10n.archiveExplain, icon: Icons.inventory_2_outlined),
              const SizedBox(height: QSpace.s3),
            ],
            Row(
              children: [
                if (_isEdit)
                  QButton(
                    label: (widget.existing?.archived ?? false)
                        ? l10n.unarchiveTracker
                        : l10n.archiveTracker,
                    kind: QButtonKind.outline,
                    small: true,
                    icon: Icons.inventory_2_outlined,
                    onPressed: () => unawaited(_archive()),
                  ),
                const Spacer(),
                QButton(
                  label: l10n.save,
                  small: true,
                  onPressed: () => unawaited(_save()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _TargetStepper extends StatelessWidget {
  const _TargetStepper({
    required this.value,
    required this.step,
    required this.onChanged,
  });

  final int? value;
  final int step;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: q.surface2,
        borderRadius: BorderRadius.circular(QRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(QRadius.full),
            onTap: value == null
                ? null
                : () => onChanged(value! - step <= 0 ? null : value! - step),
            child: Container(
              width: 34,
              height: 34,
              decoration:
                  BoxDecoration(color: q.surface, shape: BoxShape.circle),
              child: Icon(
                Icons.remove,
                size: 16,
                color: value == null ? q.ink3 : q.ink,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              value?.toString() ?? '—',
              textAlign: TextAlign.center,
              style: QType.num_(QType.titleSm).copyWith(color: q.ink),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(QRadius.full),
            onTap: () => onChanged((value ?? 0) + step),
            child: Container(
              width: 34,
              height: 34,
              decoration:
                  BoxDecoration(color: q.surface, shape: BoxShape.circle),
              child: Icon(Icons.add, size: 16, color: q.ink),
            ),
          ),
        ],
      ),
    );
  }
}

final class _PickCircle extends StatelessWidget {
  const _PickCircle({
    required this.selected,
    required this.onTap,
    this.child,
    this.fill,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget? child;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return InkWell(
      borderRadius: BorderRadius.circular(QRadius.full),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: fill ?? (selected ? q.primary : q.surface2),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? q.ink : q.line,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
