import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../config/assets.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../domain/entities/lineage.dart';
import '../state/prophets_store.dart';
import '../widgets/lineage_painter.dart';

/// Two tabs: the 25 prophets named in the Quran, Adam to Muhammad ﷺ, as a
/// vertical timeline-tree; and the full lineage with everyone between them.
final class ProphetsScreen extends StatefulWidget {
  const ProphetsScreen({super.key});

  @override
  State<ProphetsScreen> createState() => _ProphetsScreenState();
}

final class _ProphetsScreenState extends State<ProphetsScreen> {
  // App-scoped store — never disposed here.
  late final ProphetsStore _store = locator<ProphetsStore>();

  static const _rowHeight = 72.0;
  static const _lineageRowHeight = 52.0;
  static const _laneWidth = 16.0;

  @override
  void initState() {
    super.initState();
    if (!_store.loaded.value) {
      unawaited(_store.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.prophetsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.prophetsTabProphets),
              Tab(text: l10n.prophetsTabLineage),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              SignalBuilder(
                builder: (context) => _tree(
                  context,
                  rows: _store.rows.value,
                  failed: _store.failed.value,
                  rowHeight: _rowHeight,
                ),
              ),
              SignalBuilder(
                builder: (context) => _tree(
                  context,
                  rows: _store.lineageRows.value,
                  failed: _store.lineageFailed.value,
                  rowHeight: _lineageRowHeight,
                  prophetIds: _store.prophetIds.value,
                  note: l10n.prophetsLineageNote,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One tab's tree. With [prophetIds], rows outside it are lineage people:
  /// a muted dot and no detail page.
  Widget _tree(
    BuildContext context, {
    required List<LineageRow> rows,
    required bool failed,
    required double rowHeight,
    Set<String>? prophetIds,
    String? note,
  }) {
    final l10n = context.l10n;
    if (rows.isEmpty && failed) {
      return QErrorRetry(
        message: l10n.prophetsLoadError,
        retryLabel: l10n.retry,
        onRetry: () => unawaited(_store.load()),
      );
    }
    if (rows.isEmpty && !_store.loaded.value) {
      return const QSkeletonList();
    }
    final lanes = rows.fold(
      1,
      (n, r) =>
          math.max(n, [r.column, ...r.outgoing.keys].reduce(math.max) + 1),
    );
    // About half the row is text: grow that half with the text scale so two
    // lines still fit at 2x.
    final textPart = rowHeight / 2;
    final textScaler = MediaQuery.textScalerOf(context);
    final list = ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: QSpace.s3),
      itemExtent: rowHeight - textPart + textScaler.scale(textPart),
      itemCount: rows.length,
      itemBuilder: (context, index) => _ProphetRow(
        key: ValueKey(rows[index].prophet.id),
        row: rows[index],
        treeWidth: lanes * _laneWidth,
        isProphet: prophetIds?.contains(rows[index].prophet.id) ?? true,
      ),
    );
    if (note == null) return list;
    final q = context.q;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            QSpace.s5,
            QSpace.s3,
            QSpace.s5,
            0,
          ),
          child: Text(note, style: QType.caption.copyWith(color: q.ink3)),
        ),
        Expanded(child: list),
      ],
    );
  }
}

final class _ProphetRow extends StatelessWidget {
  const _ProphetRow({
    required this.row,
    required this.treeWidth,
    required this.isProphet,
    super.key,
  });

  final LineageRow row;
  final double treeWidth;

  /// False for a lineage person: muted, and no detail page to open.
  final bool isProphet;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    final prophet = row.prophet;
    final title = prophet.titleFor(languageCode);
    return InkWell(
      onTap: isProphet
          ? () => unawaited(
              context.pushNamed(
                Routes.prophet.name,
                pathParameters: {'id': prophet.id},
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: QSpace.s5),
        child: Row(
          children: [
            SizedBox(
              width: treeWidth,
              height: double.infinity,
              child: CustomPaint(
                painter: LineagePainter(
                  row: row,
                  laneWidth: _ProphetsScreenState._laneWidth,
                  lineColor: q.lineStrong,
                  dotColor: isProphet ? q.primary : q.ink3,
                  textDirection: Directionality.of(context),
                ),
              ),
            ),
            const SizedBox(width: QSpace.s3),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prophet.nameFor(languageCode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: isProphet
                        ? QType.titleSm.copyWith(color: q.ink)
                        : QType.body.copyWith(color: q.ink2),
                  ),
                  if (title.isNotEmpty)
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: QType.caption.copyWith(color: q.ink3),
                    ),
                ],
              ),
            ),
            if (prophet.nameAr.isNotEmpty) ...[
              const SizedBox(width: QSpace.s3),
              Text(
                prophet.nameAr,
                textDirection: TextDirection.rtl,
                style: QType.titleSm.copyWith(
                  fontFamily: AppFonts.arabicUi,
                  color: q.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
