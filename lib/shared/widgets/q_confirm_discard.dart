import 'package:flutter/material.dart';

import '../extensions/context_ext.dart';

/// Asks before an edited sheet is closed without saving; true = discard.
Future<bool> confirmDiscard(BuildContext context) async {
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
