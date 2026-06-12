import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../config/app_config.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/surah.dart';
import '../state/quran_store.dart';
import '../widgets/ayah_medallion.dart';

/// Estimated ayah-card extent for index→offset jumps and the visible-ayah
/// estimate (cards are not fixed-extent; an estimate is acceptable here).
const _estimatedCardExtent = 180.0;

/// Surah reader (design §4.5): ayah cards with the Uthmanic HAFS script at
/// an independent user scale, per-ayah bookmark/copy actions, a scroll
/// progress bar under the app bar and a reading-settings sheet.
final class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({
    required this.surahId,
    this.initialAyah,
    super.key,
  });

  final int surahId;

  /// Ayah number within the surah to jump to (resume / deep links).
  final int? initialAyah;

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

final class _QuranReaderScreenState extends State<QuranReaderScreen> {
  // App-scoped store — never disposed here.
  late final QuranStore _store = locator<QuranStore>();

  final ScrollController _controller = ScrollController();
  final _ayahs = signal(const <Ayah>[]);
  final _progress = signal(0.0);

  Timer? _markReadDebounce;
  int _lastBuiltIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    unawaited(_load());
  }

  @override
  void dispose() {
    _markReadDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _ayahs.value = await _store.ayahsOf(widget.surahId);
    final initial = widget.initialAyah;
    if (initial != null && initial > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) {
          return;
        }
        _controller.jumpTo(
          ((initial - 1) * _estimatedCardExtent)
              .clamp(0.0, _controller.position.maxScrollExtent),
        );
      });
    }
  }

  void _onScroll() {
    final position = _controller.position;
    _progress.value = position.maxScrollExtent <= 0
        ? 0
        : (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0).toDouble();
  }

  /// Cheap visibility tracking: remember the last built index and, after
  /// 500ms of quiet, record the first visible ayah (offset estimate).
  void _trackVisible(int builtIndex) {
    _lastBuiltIndex = builtIndex;
    _markReadDebounce?.cancel();
    _markReadDebounce = Timer(const Duration(milliseconds: 500), _markRead);
  }

  void _markRead() {
    final ayahs = _ayahs.value;
    if (ayahs.isEmpty) {
      return;
    }
    var index = _lastBuiltIndex;
    if (_controller.hasClients) {
      index = (_controller.offset / _estimatedCardExtent).floor();
    }
    if (index < 0) {
      index = 0;
    } else if (index >= ayahs.length) {
      index = ayahs.length - 1;
    }
    unawaited(
      _store.markRead(QuranPosition(widget.surahId, ayahs[index].number)),
    );
  }

  Surah? _surah() {
    for (final surah in _store.surahs.value) {
      if (surah.id == widget.surahId) {
        return surah;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Scaffold(
      appBar: AppBar(
        title: SignalBuilder(
          builder: (context) => Text(
            _surah()?.transliteration ?? context.l10n.quranTitle,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => unawaited(_openReaderSettings(context)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: SignalBuilder(
            builder: (context) => LinearProgressIndicator(
              value: _progress.value,
              minHeight: 3,
              backgroundColor: q.surface2,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final ayahs = _ayahs.value;
            if (ayahs.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(QSpace.s5),
                children: [
                  for (var i = 0; i < 5; i++) ...[
                    const QSkeleton(height: 140, radius: QRadius.lg),
                    const SizedBox(height: QSpace.s3),
                  ],
                ],
              );
            }
            return ListView.builder(
              controller: _controller,
              padding: const EdgeInsetsDirectional.fromSTEB(
                QSpace.s5,
                QSpace.s3,
                QSpace.s5,
                QSpace.s5,
              ),
              itemCount: ayahs.length,
              itemBuilder: (context, index) {
                _trackVisible(index);
                return Padding(
                  padding:
                      const EdgeInsetsDirectional.only(bottom: QSpace.s3),
                  // Lazy items build outside the body SignalBuilder's
                  // tracked scope, so each card subscribes on its own.
                  child: SignalBuilder(
                    builder: (context) => _ayahCard(context, ayahs[index]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _ayahCard(BuildContext context, Ayah ayah) {
    final l10n = context.l10n;
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    final bookmarked = _store.bookmarks.value.contains(ayah.id);
    return QCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [AyahMedallion(number: ayah.number, size: 34)]),
          const SizedBox(height: QSpace.s3),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              ayah.arabic,
              style: QType.quran(_store.readerFontSize.value)
                  .copyWith(color: q.ink),
            ),
          ),
          if (_store.showTranslation.value) ...[
            const SizedBox(height: QSpace.s2),
            Text(
              ayah.translationFor(languageCode),
              style: QType.body.copyWith(color: q.ink2),
            ),
          ],
          const SizedBox(height: QSpace.s1),
          Row(
            children: [
              IconButton(
                tooltip: l10n.bookmarkLabel,
                icon: Icon(
                  bookmarked ? Icons.bookmark : Icons.bookmark_outline,
                  color: bookmarked ? q.primary : q.ink3,
                ),
                onPressed: () => unawaited(_store.toggleBookmark(ayah.id)),
              ),
              IconButton(
                icon: Icon(Icons.copy_outlined, color: q.ink3),
                onPressed: () => unawaited(_copyAyah(context, ayah)),
              ),
              // Share lands with the share-sheet integration phase.
              IconButton(
                icon: Icon(Icons.share_outlined, color: q.ink3),
                onPressed: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyAyah(BuildContext context, Ayah ayah) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    await Clipboard.setData(
      ClipboardData(
        text: '${ayah.arabic}\n'
            '${ayah.translationFor(languageCode)}\n'
            '${l10n.ayahShareSuffix(ayah.surah, ayah.number)}',
      ),
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.ayahCopied)));
  }

  Future<void> _openReaderSettings(BuildContext context) {
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
              final size = _store.readerFontSize.value;
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
                    divisions: ((AppConfig.quranFontSizeMax -
                                AppConfig.quranFontSizeMin) /
                            AppConfig.quranFontSizeStep)
                        .round(),
                    label: LocaleDigits.localize(
                      '${size.round()}',
                      Localizations.localeOf(context).languageCode,
                    ),
                    onChanged: (value) =>
                        unawaited(_store.setReaderFontSize(value)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.showTranslation,
                      style: QType.titleSm.copyWith(color: q.ink),
                    ),
                    value: _store.showTranslation.value,
                    onChanged: (value) =>
                        unawaited(_store.setShowTranslation(value: value)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
