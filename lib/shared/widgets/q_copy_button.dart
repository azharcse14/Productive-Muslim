import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../extensions/context_ext.dart';

/// Copies [text] to the clipboard and confirms with a snackbar (duas,
/// hadith, ruqyah — passages people share).
final class QCopyButton extends StatelessWidget {
  const QCopyButton({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IconButton(
      tooltip: l10n.copyLabel,
      icon: Icon(Icons.copy_outlined, color: context.q.ink3),
      onPressed: () {
        final messenger = ScaffoldMessenger.of(context);
        unawaited(
          Clipboard.setData(ClipboardData(text: text)).then(
            (_) => messenger.showSnackBar(
              SnackBar(content: Text(l10n.copiedLabel)),
            ),
          ),
        );
      },
    );
  }
}
