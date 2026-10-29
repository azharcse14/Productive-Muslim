import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../config/app_config.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../state/quran_store.dart';

/// Reading-settings sheet: the Arabic size slider (shared by the Quran
/// reader and the dua/hadith/ruqyah screens, whose Arabic follows it via
/// [arabicBodySize]) and, in the Quran reader, the translation toggle.
Future<void> showReaderSettingsSheet(
  BuildContext context, {
  bool showTranslationToggle = false,
  VoidCallback? onFontChangeStart,
  VoidCallback? onFontChanged,
}) {
  final store = GetIt.I<QuranStore>();
  final l10n = context.l10n;
  return showModalBottomSheet<void>(
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
            final size = store.readerFontSize.value;
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
                  label: LocaleDigits.localize(
                    '${size.round()}',
                    Localizations.localeOf(context).languageCode,
                  ),
                  // Persist once on release, not on every tick.
                  onChangeStart: (_) => onFontChangeStart?.call(),
                  onChanged: (value) {
                    unawaited(store.setReaderFontSize(value, persist: false));
                    onFontChanged?.call();
                  },
                  onChangeEnd: (value) =>
                      unawaited(store.setReaderFontSize(value)),
                ),
                if (showTranslationToggle)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.showTranslation,
                      style: QType.titleSm.copyWith(color: q.ink),
                    ),
                    value: store.showTranslation.value,
                    onChanged: (value) =>
                        unawaited(store.setShowTranslation(value: value)),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// App-bar action opening [showReaderSettingsSheet] (text size only).
/// Hidden when the Quran store isn't available (DB failed to open).
final class ReaderSettingsAction extends StatelessWidget {
  const ReaderSettingsAction({super.key});

  @override
  Widget build(BuildContext context) {
    if (!GetIt.I.isRegistered<QuranStore>()) {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: context.l10n.readerSettings,
      icon: const Icon(Icons.text_fields),
      onPressed: () {
        final store = GetIt.I<QuranStore>();
        if (!store.loaded.value) {
          unawaited(store.load());
        }
        unawaited(showReaderSettingsSheet(context));
      },
    );
  }
}
