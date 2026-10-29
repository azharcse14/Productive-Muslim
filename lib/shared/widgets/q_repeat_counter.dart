import 'package:flutter/material.dart';

import '../../core/utils/haptics.dart';
import '../../core/utils/locale_digits.dart';
import '../extensions/context_ext.dart';
import 'q_chip.dart';

/// "×N" chip that counts recitations on tap up to [repeat] (long-press or
/// the reset button clears it). A session counter — not persisted; a started
/// count survives scrolling out of a lazy list.
final class QRepeatCounter extends StatefulWidget {
  const QRepeatCounter({required this.repeat, super.key});

  final int repeat;

  @override
  State<QRepeatCounter> createState() => _QRepeatCounterState();
}

final class _QRepeatCounterState extends State<QRepeatCounter>
    with AutomaticKeepAliveClientMixin {
  int _count = 0;

  @override
  bool get wantKeepAlive => _count > 0;

  void _increment() {
    if (_count >= widget.repeat) {
      return;
    }
    setState(() => _count++);
    updateKeepAlive();
    if (_count == widget.repeat) {
      Haptics.medium();
    }
  }

  void _reset() {
    if (_count == 0) {
      return;
    }
    Haptics.selection();
    setState(() => _count = 0);
    updateKeepAlive();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final repeat = widget.repeat;
    final languageCode = Localizations.localeOf(context).languageCode;
    String digits(int n) => LocaleDigits.localize('$n', languageCode);
    return Row(
      children: [
        Semantics(
          button: true,
          label: l10n.duaRepeatCounterLabel(digits(_count), digits(repeat)),
          onTap: _increment,
          onLongPress: _reset,
          excludeSemantics: true,
          child: GestureDetector(
            onLongPress: _reset,
            child: QChip(
              label: _count == 0
                  ? LocaleDigits.localize(
                      l10n.repeatTimes(repeat),
                      languageCode,
                    )
                  : l10n.duaRepeatProgress(digits(_count), digits(repeat)),
              icon: _count >= repeat ? Icons.check : null,
              active: true,
              onTap: _increment,
            ),
          ),
        ),
        if (_count > 0)
          IconButton(
            tooltip: l10n.tasbihReset,
            icon: Icon(Icons.restart_alt, size: 20, color: context.q.ink3),
            onPressed: _reset,
          ),
      ],
    );
  }
}
