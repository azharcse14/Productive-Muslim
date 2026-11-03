import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_list_row.dart';
import '../../../../shared/widgets/q_medallion.dart';
import '../../../../shared/widgets/q_pressable.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/juz.dart';
import '../../domain/entities/surah.dart';
import '../state/quran_store.dart';
import '../widgets/quran_unavailable.dart';

/// Quran tab (design §4.5): continue-reading resume card, surah search
/// and the 114-surah index; rows open the reader.
final class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) => locator.isRegistered<QuranStore>()
      ? const _QuranIndex()
      : const QuranUnavailable();
}

final class _QuranIndex extends StatefulWidget {
  const _QuranIndex();

  @override
  State<_QuranIndex> createState() => _QuranIndexState();
}

final class _QuranIndexState extends State<_QuranIndex> {
  // App-scoped store — never disposed here.
  late final QuranStore _store = locator<QuranStore>();

  /// null = no active query (show the full index from the store).
  final _results = signal<List<Surah>?>(null);

  /// The query read as a "2:255" reference, offered as a direct jump.
  final _reference = signal<QuranPosition?>(null);

  Timer? _debounce;

  final _query = TextEditingController();

  /// Bookmarks removed while the sheet is open, newest last; each undo
  /// puts back the latest.
  final _removedBookmarks = signal(const <int>[]);

  /// One read per surah for the bookmark previews, shared across rows.
  final Map<int, Future<List<Ayah>?>> _previewAyahs = {};

  @override
  void initState() {
    super.initState();
    if (!_store.loaded.value) {
      unawaited(_store.load());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(_runSearch(query)),
    );
  }

  var _searchSeq = 0;

  Future<void> _runSearch(String query) async {
    final seq = ++_searchSeq;
    final reference = parseAyahReference(_store.surahs.value, query);
    final results = query.trim().isEmpty
        ? null
        : reference != null
        ? [?_surahById(reference.surah)]
        : await _store.search(query);
    // A slower earlier query must not overwrite a newer one's results.
    if (seq == _searchSeq) {
      _reference.value = reference;
      _results.value = results;
    }
  }

  void _openReader(int surahId, {int? initialAyah}) {
    unawaited(
      initialAyah == null
          ? context.pushNamed(
              Routes.quranReader.name,
              pathParameters: {'surah': '$surahId'},
            )
          : context.pushNamed(
              Routes.quranAyah.name,
              pathParameters: {'surah': '$surahId', 'ayah': '$initialAyah'},
            ),
    );
  }

  void _removeBookmark(int id) {
    _removedBookmarks.value = [..._removedBookmarks.value, id];
    unawaited(_store.toggleBookmark(id));
  }

  void _showBookmarks() {
    _removedBookmarks.value = const [];
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => SignalBuilder(builder: _bookmarksSheet),
      ),
    );
  }

  Widget _bookmarksSheet(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    final ids = _store.bookmarks.value.toList()..sort();
    final removed = _removedBookmarks.value;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(QSpace.s5),
              child: Text(
                l10n.bookmarksTitle,
                style: QType.title.copyWith(color: q.ink),
              ),
            ),
            if (removed.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  QSpace.s5,
                  0,
                  QSpace.s3,
                  QSpace.s2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.bookmarkRemoved,
                        style: QType.body.copyWith(color: q.ink2),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _removedBookmarks.value = removed.sublist(
                          0,
                          removed.length - 1,
                        );
                        unawaited(_store.toggleBookmark(removed.last));
                      },
                      child: Text(l10n.bookmarkUndo),
                    ),
                  ],
                ),
              ),
            if (ids.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  QSpace.s5,
                  0,
                  QSpace.s5,
                  QSpace.s6,
                ),
                child: Text(
                  l10n.bookmarksEmpty,
                  style: QType.body.copyWith(color: q.ink2),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: QSpace.s5),
                  itemCount: ids.length,
                  itemBuilder: (context, index) {
                    final id = ids[index];
                    return switch (_store.positionOf(id)) {
                      null => const SizedBox.shrink(),
                      final position => Dismissible(
                        key: ValueKey(id),
                        onDismissed: (_) => _removeBookmark(id),
                        child: FutureBuilder(
                          future: _previewAyahs.putIfAbsent(
                            position.surah,
                            () async {
                              final a = await _store.ayahsOf(position.surah);
                              // A failed read isn't cached: the next
                              // build retries it.
                              if (a == null) {
                                _previewAyahs.removeWhere(
                                  (k, _) => k == position.surah,
                                );
                              }
                              return a;
                            },
                          ),
                          builder: (context, snapshot) {
                            final reference = LocaleDigits.localize(
                              '${position.surah}:${position.ayah}',
                              languageCode,
                            );
                            final preview = _preview(
                              snapshot.data,
                              position.ayah,
                              languageCode,
                            );
                            return QListRow(
                              icon: Icons.bookmark_outline,
                              title:
                                  _surahById(position.surah)?.transliteration ??
                                  '',
                              subtitle: preview == null
                                  ? reference
                                  : '$reference · $preview',
                              // The swipe has a visible, labelled twin.
                              trailing: IconButton(
                                tooltip: l10n.bookmarkRemoveTooltip,
                                icon: Icon(Icons.delete_outline, color: q.ink3),
                                onPressed: () => _removeBookmark(id),
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                _openReader(
                                  position.surah,
                                  initialAyah: position.ayah,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    };
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// First words of the bookmarked ayah's translation, or null until the
  /// surah has been read.
  static String? _preview(List<Ayah>? ayahs, int number, String languageCode) {
    final ayah = ayahs?.where((a) => a.number == number).firstOrNull;
    if (ayah == null) {
      return null;
    }
    final text = ayah.translationFor(languageCode).trim();
    return text.length <= 60 ? text : '${text.substring(0, 60).trimRight()}…';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.quranTitle),
          actions: [
            IconButton(
              tooltip: l10n.bookmarksTitle,
              icon: const Icon(Icons.bookmarks_outlined),
              onPressed: _showBookmarks,
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.quranJuzTabSurahs),
              Tab(text: l10n.quranJuzTabJuz),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              SignalBuilder(
                builder: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        QSpace.s5,
                        QSpace.s3,
                        QSpace.s5,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_store.lastRead.value != null) ...[
                            _resumeCard(context),
                            const SizedBox(height: QSpace.s3),
                          ] else if (_store.loaded.value) ...[
                            QBanner(
                              text: l10n.quranFirstOpen,
                              icon: Icons.menu_book_outlined,
                            ),
                            const SizedBox(height: QSpace.s3),
                          ],
                          ListenableBuilder(
                            listenable: _query,
                            builder: (context, _) => TextField(
                              controller: _query,
                              onChanged: _onQueryChanged,
                              onSubmitted: (query) {
                                if (parseAyahReference(
                                      _store.surahs.value,
                                      query,
                                    )
                                    case final p?) {
                                  _openReader(p.surah, initialAyah: p.ayah);
                                }
                              },
                              decoration: InputDecoration(
                                hintText: l10n.searchSurahHint,
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _query.text.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: l10n.clearSearch,
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          _query.clear();
                                          _debounce?.cancel();
                                          unawaited(_runSearch(''));
                                        },
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: QSpace.s2),
                    Expanded(child: _surahList(context)),
                  ],
                ),
              ),
              SignalBuilder(builder: _juzList),
            ],
          ),
        ),
      ),
    );
  }

  /// The 30 juz; each row opens the reader at the juz's first ayah.
  Widget _juzList(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    return ListView.builder(
      key: const PageStorageKey('quranJuzList'),
      padding: const EdgeInsets.symmetric(
        horizontal: QSpace.s5,
        vertical: QSpace.s2,
      ),
      itemCount: juzStarts.length,
      itemBuilder: (context, index) {
        final start = juzStarts[index];
        final reference = LocaleDigits.localize(
          '${start.surah}:${start.ayah}',
          languageCode,
        );
        final name = _surahById(start.surah)?.transliteration;
        return QPressable(
          onTap: () => _openReader(start.surah, initialAyah: start.ayah),
          borderRadius: BorderRadius.circular(QRadius.md),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 2,
              vertical: QSpace.s2,
            ),
            child: Row(
              children: [
                QMedallion(number: index + 1),
                const SizedBox(width: QSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.quranJuzTitle(
                          LocaleDigits.localize('${index + 1}', languageCode),
                        ),
                        style: QType.titleSm.copyWith(color: q.ink),
                      ),
                      Text(
                        name == null ? reference : '$name · $reference',
                        style: QType.caption.copyWith(color: q.ink2),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: q.ink3),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _resumeCard(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final position = _store.lastRead.value;
    if (position == null) {
      return const SizedBox.shrink();
    }
    final surah = _surahById(position.surah);
    final ayahLabel = l10n.continueReadingAyah(
      LocaleDigits.localize(
        '${position.ayah}',
        Localizations.localeOf(context).languageCode,
      ),
    );
    return QCard(
      padding: const EdgeInsets.symmetric(
        horizontal: QSpace.s4,
        vertical: QSpace.s2,
      ),
      child: QListRow(
        icon: Icons.menu_book_outlined,
        title: l10n.continueReading,
        subtitle: surah == null
            ? null
            : '${surah.transliteration} · $ayahLabel',
        trailing: Icon(Icons.chevron_right, color: q.ink3),
        onTap: () => _openReader(position.surah, initialAyah: position.ayah),
      ),
    );
  }

  Surah? _surahById(int id) {
    for (final surah in _store.surahs.value) {
      if (surah.id == id) {
        return surah;
      }
    }
    return null;
  }

  Widget _surahList(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    if (_store.failed.value) {
      return QErrorRetry(
        message: l10n.quranLoadError,
        retryLabel: l10n.retry,
        onRetry: () => unawaited(_store.load()),
      );
    }
    if (!_store.loaded.value) {
      return ListView(
        padding: const EdgeInsets.all(QSpace.s5),
        children: [
          for (var i = 0; i < 8; i++) ...[
            const QSkeleton(height: 52, radius: QRadius.sm),
            const SizedBox(height: QSpace.s2),
          ],
        ],
      );
    }
    final surahs = _results.value ?? _store.surahs.value;
    if (surahs.isEmpty) {
      return Center(
        child: Text(
          l10n.surahSearchNoResults,
          style: QType.body.copyWith(color: q.ink2),
        ),
      );
    }
    final reference = _results.value == null ? null : _reference.value;
    if (reference != null) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: QSpace.s5),
        children: [
          QListRow(
            icon: Icons.menu_book_outlined,
            title: l10n.quranOpenAyah(
              LocaleDigits.localize(
                '${reference.surah}:${reference.ayah}',
                Localizations.localeOf(context).languageCode,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: q.ink3),
            onTap: () =>
                _openReader(reference.surah, initialAyah: reference.ayah),
          ),
          for (final surah in surahs) _surahRow(context, surah),
        ],
      );
    }
    return ListView.builder(
      // Tab switches rebuild this page; keep its scroll offset.
      key: const PageStorageKey('quranSurahList'),
      padding: const EdgeInsets.symmetric(horizontal: QSpace.s5),
      itemCount: surahs.length,
      itemBuilder: (context, index) => index < 10
          ? StaggeredEntrance(
              index: index,
              child: _surahRow(context, surahs[index]),
            )
          : _surahRow(context, surahs[index]),
    );
  }

  Widget _surahRow(BuildContext context, Surah surah) {
    final l10n = context.l10n;
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    return QPressable(
      onTap: () => _openReader(surah.id),
      borderRadius: BorderRadius.circular(QRadius.md),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 2,
          vertical: QSpace.s2,
        ),
        child: Row(
          children: [
            QMedallion(number: surah.id),
            const SizedBox(width: QSpace.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.transliteration,
                    style: QType.titleSm.copyWith(color: q.ink),
                  ),
                  // No Bengali surah meanings in the data; never show the
                  // English one in a Bengali UI.
                  if (languageCode == 'en')
                    Text(
                      surah.translationEn,
                      style: QType.caption.copyWith(color: q.ink2),
                    ),
                  Text(
                    l10n.surahMeta(
                      surah.ayahCount,
                      l10n.revelationName(surah.revelation),
                    ),
                    style: QType.caption.copyWith(color: q.ink2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: QSpace.s3),
            Text(
              surah.nameArabic,
              style: QType.quran(20).copyWith(color: q.ink),
            ),
          ],
        ),
      ),
    );
  }
}
