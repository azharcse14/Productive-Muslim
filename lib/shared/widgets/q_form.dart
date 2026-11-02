import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import 'q_confirm_discard.dart';

/// Input formatters for numeric fields; accept Western, Bengali and
/// Arabic-Indic digits (parse with `LocaleDigits.toAscii`).
abstract final class QInputFormat {
  /// Whole numbers only.
  static final digits = [
    FilteringTextInputFormatter.allow(RegExp('[0-9০-৯٠-٩۰-۹]')),
  ];

  /// Amounts: digits plus decimal/grouping separators ('.', ',', '٫', '٬').
  static final decimal = [
    FilteringTextInputFormatter.allow(RegExp('[0-9০-৯٠-٩۰-۹.,٫٬]')),
  ];
}

/// Scrolls the widget under [key] into view once the next frame has laid it
/// out (e.g. a freshly shown calculator result). Cut under reduced motion.
void revealAfterFrame(BuildContext context, GlobalKey key) {
  final reduced = MediaQuery.disableAnimationsOf(context);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final target = key.currentContext;
    if (target == null || !target.mounted) {
      return;
    }
    unawaited(
      Scrollable.ensureVisible(
        target,
        alignment: 0.1,
        duration: reduced ? Duration.zero : QMotion.med,
        curve: QMotion.ease,
      ),
    );
  });
}

/// `TextField.onTapOutside` handler: dismisses the keyboard (number pads
/// have no done key on iOS).
void unfocusOnTapOutside(PointerDownEvent _) =>
    FocusManager.instance.primaryFocus?.unfocus();

/// Asks before leaving a form whose input would be lost: back is held
/// while [dirty] and confirmed through [confirmDiscard].
final class QDiscardGuard extends StatelessWidget {
  const QDiscardGuard({required this.dirty, required this.child, super.key});

  final bool dirty;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty,
    onPopInvokedWithResult: (didPop, _) async {
      final navigator = Navigator.of(context);
      if (!didPop && await confirmDiscard(context)) {
        navigator.pop();
      }
    },
    child: child,
  );
}
