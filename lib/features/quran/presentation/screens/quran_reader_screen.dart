import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../config/app_config.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/surah.dart';
import '../state/quran_store.dart';
import '../widgets/ayah_medallion.dart';

/// Estimated ayah-card extent for the initial index→offset jump (cards are
/// not fixed-extent; an estimate is acceptable for a resume jump).
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

  /// Contexts of the currently built ayah items, keyed by index — used to
  /// find the ayah actually at the top of the viewport.
  final Map<int, BuildContext> _itemContexts = {};

  /// Last-read is only recorded once the user has scrolled themselves, so
  /// opening and leaving (or the programmatic resume jump) never overwrites
  /// it with ayah 1.
  bool _userScrolled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    unawaited(_load());
  }

  @override
  void dispose() {
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

  /// Index of the built item covering the viewport's leading edge: the one
  /// with the greatest reveal offset not past the current scroll offset.
  int? _topVisibleIndex() {
    if (!_controller.hasClients) {
      return null;
    }
    final pixels = _controller.offset;
    int? top;
    double? topReveal;
    int? first;
    _itemContexts.removeWhere((_, context) => !context.mounted);
    for (final MapEntry(key: index, value: context) in _itemContexts.entries) {
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.attached) {
        continue;
      }
      if (first == null || index < first) {
        first = index;
      }
      final reveal =
          RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset;
      if (reveal <= pixels + 0.5 && (topReveal == null || reveal > topReveal)) {
        top = index;
        topReveal = reveal;
      }
    }
    return top ?? first;
  }

  void _markRead() {
    final ayahs = _ayahs.value;
    final index = _topVisibleIndex();
    if (!mounted || ayahs.isEmpty || index == null || index >= ayahs.length) {
      return;
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
            return NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is UserScrollNotification) {
                  _userScrolled = true;
                } else if (n is ScrollEndNotification && _userScrolled) {
                  // Once per settled scroll (not per frame): record the
                  // ayah at the top of the viewport, after the frame that
                  // lays the items out at the final offset.
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _markRead());
                }
                return false;
              },
              child: ListView.builder(
                controller: _controller,
                padding: const EdgeInsetsDirectional.fromSTEB(
                  QSpace.s5,
                  QSpace.s3,
                  QSpace.s5,
                  QSpace.s5,
                ),
                itemCount: ayahs.length,
                // The builder context is the sliver's, so each item gets its
                // own Builder context for the top-visible-ayah lookup.
                itemBuilder: (_, index) => Builder(
                  builder: (itemContext) {
                    _itemContexts[index] = itemContext;
                    return Padding(
                      padding:
                          const EdgeInsetsDirectional.only(bottom: QSpace.s3),
                      // Lazy items build outside the body SignalBuilder's
                      // tracked scope, so each card subscribes on its own.
                      child: SignalBuilder(
                        builder: (context) =>
                            _ayahCard(context, ayahs[index]),
                      ),
                    );
                  },
                ),
              ),
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
