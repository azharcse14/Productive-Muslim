import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../config/app_config.dart';
import '../../core/theme/productive_muslim_tokens.dart';
import '../../core/theme/productive_muslim_typography.dart';
import '../extensions/context_ext.dart';
import 'reader_text_size.dart';

/// Reading-settings sheet: the Arabic size slider (shared by the Quran
/// reader and the dua/hadith/ruqyah screens, whose Arabic follows it via
/// [arabicBodySize]) plus any [extras] below it (the Quran reader's
/// translation toggle). Built inside a SignalBuilder, so [extras] may read
/// signals. No-op without a [ReaderTextSizeScope].
Future<void> showReaderSettingsSheet(
  BuildContext context, {
  List<Widget> Function(BuildContext context)? extras,
  VoidCallback? onFontChangeStart,
  VoidCallback? onFontChanged,
}) async {
  final textSize = ReaderTextSizeScope.maybeOf(context);
  if (textSize == null) {
    return;
  }
  final l10n = context.l10n;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          QSpace.s5,
          0,
          QSpace.s5,
          QSpace.s5,
        ),
        child: SignalBuilder(
          builder: (context) {
            final q = context.q;
            final size = textSize.size.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.readerFontSize,
                  style: QType.label.copyWith(color: q.ink),
                ),
                Slider(
                  value: size,
                  min: AppConfig.quranFontSizeMin,
                  max: AppConfig.quranFontSizeMax,
                  divisions:
                      ((AppConfig.quranFontSizeMax -
                                  AppConfig.quranFontSizeMin) /
                              AppConfig.quranFontSizeStep)
                          .round(),
                  label: context.digits('${size.round()}'),
                  // Announce the size, not the default percentage.
                  semanticFormatterCallback: (value) =>
                      context.digits('${value.round()}'),
                  // Persist once on release, not on every tick.
                  onChangeStart: (_) => onFontChangeStart?.call(),
                  onChanged: (value) {
                    unawaited(textSize.set(value, persist: false));
                    onFontChanged?.call();
                  },
                  onChangeEnd: (value) async {
                    if (!await textSize.set(value) && context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l10n.saveFailed)));
                    }
                  },
                ),
                ...?extras?.call(context),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// App-bar action opening [showReaderSettingsSheet] (text size only).
/// Hidden without a [ReaderTextSizeScope].
final class ReaderSettingsAction extends StatelessWidget {
  const ReaderSettingsAction({super.key});

  @override
  Widget build(BuildContext context) {
    if (ReaderTextSizeScope.maybeOf(context) == null) {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: context.l10n.readerSettings,
      icon: const Icon(Icons.text_fields),
      onPressed: () => unawaited(showReaderSettingsSheet(context)),
    );
  }
}
