import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../config/app_config.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/surah.dart';
import '../state/quran_store.dart';
import '../widgets/ayah_medallion.dart';

/// Ayah-card extent guess for the first index→offset jump, before any card
/// has been measured. The jump then refines itself (see `_jumpToIndex`).
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
  final _failed = signal(false);
  final _progress = signal(0.0);

  /// Contexts of the currently built ayah items, keyed by index — used to
  /// find the ayah actually at the top of the viewport.
  final Map<int, BuildContext> _itemContexts = {};

  /// Last-read is only recorded once the user has scrolled themselves, so
  /// opening and leaving (or the programmatic resume jump) never overwrites
  /// it with ayah 1.
  bool _userScrolled = false;

  /// Top visible ayah index captured when a font-size drag starts.
  int? _fontAnchor;

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
    _failed.value = false;
    final ayahs = await _store.ayahsOf(widget.surahId);
    // An empty surah is a broken/missing DB row, not "still loading".
    _failed.value = ayahs == null || ayahs.isEmpty;
    _ayahs.value = ayahs ?? const [];
    final initial = widget.initialAyah;
    if (initial != null && initial > 1) {
      final index = _ayahs.value.indexWhere((a) => a.number == initial);
      if (index > 0) {
        _jumpToIndex(index);
      }
    }
  }

  /// Cards vary in height (font size, translation, ayah length), so one
  /// estimated jump drifts in long surahs. Jump from the measured built
  /// cards until the target card itself is built, then reveal it exactly.
  void _jumpToIndex(int target, [int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) {
        return;
      }
      final targetContext = _itemContexts[target];
      if (targetContext != null && targetContext.mounted) {
        unawaited(Scrollable.ensureVisible(targetContext));
        return;
      }
      if (attempt >= 10) {
        return;
      }
      // Anchor on the first built card; average the built cards' extents.
      int? anchor;
      var anchorOffset = 0.0;
      var total = 0.0;
      var count = 0;
      for (final MapEntry(key: index, value: context)
          in _itemContexts.entries) {
        final box = context.mounted ? context.findRenderObject() : null;
        if (box is! RenderBox || !box.attached || !box.hasSize) {
          continue;
        }
        total += box.size.height;
        count++;
        if (anchor == null || index < anchor) {
          anchor = index;
          anchorOffset =
              RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset;
        }
      }
      final extent = count == 0 ? _estimatedCardExtent : total / count;
      final offset = anchor == null
          ? target * extent
          : anchorOffset + (target - anchor) * extent;
      _controller.jumpTo(
        offset.clamp(0.0, _controller.position.maxScrollExtent),
      );
      WidgetsBinding.instance.scheduleFrame();
      _jumpToIndex(target, attempt + 1);
    });
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
            tooltip: context.l10n.readerSettings,
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
            if (_failed.value) {
              return QErrorRetry(
                message: context.l10n.quranLoadError,
                retryLabel: context.l10n.hadithRetry,
                onRetry: () => unawaited(_load()),
              );
            }
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
                        builder: (context) => ayahs[index].number == 1 &&
                                widget.surahId != 1 &&
                                widget.surahId != 9
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _basmala(context),
                                  _ayahCard(context, ayahs[index]),
                                ],
                              )
                            : _ayahCard(context, ayahs[index]),
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

  /// Surah-opening basmala: not part of ayah 1 (except in al-Fatihah, and
  /// at-Tawbah has none), so it heads the surah instead of joining a card.
  Widget _basmala(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(bottom: QSpace.s3),
        child: Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          textScaler: TextScaler.noScaling,
          style: QType.quran(_store.readerFontSize.value)
              .copyWith(color: context.q.ink),
        ),
      );

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
              // The reader has its own size setting (design §4.5), so the
              // system text scale must not multiply it again.
              textScaler: TextScaler.noScaling,
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
                // Announced as selected, so a screen-reader user knows a
                // tap would remove the bookmark.
                isSelected: bookmarked,
                icon: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : QMotion.med,
                  switchInCurve: Curves.easeOutBack,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    bookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    key: ValueKey(bookmarked),
                    color: bookmarked ? q.primary : q.ink3,
                  ),
                ),
                onPressed: () {
                  bookmarked ? Haptics.selection() : Haptics.light();
                  unawaited(_store.toggleBookmark(ayah.id));
                },
              ),
              IconButton(
                tooltip: l10n.copyAyah,
                icon: Icon(Icons.copy_outlined, color: q.ink3),
                onPressed: () => unawaited(_copyAyah(context, ayah)),
              ),
              // Share returns with the share-sheet integration phase; a
              // permanently disabled button just looked broken.
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
                    // Keep the ayah at the top in place while cards resize;
                    // persist once on release, not on every tick.
                    onChangeStart: (_) => _fontAnchor = _topVisibleIndex(),
                    onChanged: (value) {
                      unawaited(
                        _store.setReaderFontSize(value, persist: false),
                      );
                      final anchor = _fontAnchor;
                      if (anchor != null) {
                        _jumpToIndex(anchor);
                      }
                    },
                    onChangeEnd: (value) =>
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
