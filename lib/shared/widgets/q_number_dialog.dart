import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/locale_digits.dart';
import '../extensions/context_ext.dart';

/// Asks for a whole number in 1..[max] (localized digits accepted); null on
/// cancel. An out-of-range entry shows [hint] as the error.
Future<int?> showNumberDialog(
  BuildContext context, {
  required String title,
  required String hint,
  required String actionLabel,
  int max = 99999,
}) => showDialog<int>(
  context: context,
  builder: (_) => _NumberDialog(
    title: title,
    hint: hint,
    actionLabel: actionLabel,
    max: max,
  ),
);

final class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.title,
    required this.hint,
    required this.actionLabel,
    required this.max,
  });

  final String title;
  final String hint;
  final String actionLabel;
  final int max;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

final class _NumberDialogState extends State<_NumberDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(LocaleDigits.toAscii(_controller.text));
    if (value == null || value < 1 || value > widget.max) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[0-9০-৯٠-٩۰-۹]')),
          LengthLimitingTextInputFormatter('${widget.max}'.length),
        ],
        decoration: InputDecoration(
          hintText: widget.hint,
          errorText: _invalid ? widget.hint : null,
        ),
        onChanged: (_) {
          if (_invalid) {
            setState(() => _invalid = false);
          }
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.actionLabel)),
      ],
    );
  }
}
