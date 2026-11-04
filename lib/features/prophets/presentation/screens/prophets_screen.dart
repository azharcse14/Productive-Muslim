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

/// The 25 prophets named in the Quran, Adam to Muhammad ﷺ, as a vertical
/// timeline; known lineages are drawn as a tree.
final class ProphetsScreen extends StatefulWidget {
  const ProphetsScreen({super.key});

  @override
  State<ProphetsScreen> createState() => _ProphetsScreenState();
}

final class _ProphetsScreenState extends State<ProphetsScreen> {
  // App-scoped store — never disposed here.
  late final ProphetsStore _store = locator<ProphetsStore>();

  static const _rowHeight = 72.0;
  static const _laneWidth = 22.0;

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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.prophetsTitle)),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final rows = _store.rows.value;
            if (rows.isEmpty && _store.failed.value) {
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
              (n, r) => math.max(
                n,
                [r.column, ...r.outgoing.keys].reduce(math.max) + 1,
              ),
            );
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: QSpace.s3),
              itemExtent: _rowHeight,
              itemCount: rows.length,
              itemBuilder: (context, index) => _ProphetRow(
                key: ValueKey(rows[index].prophet.id),
                row: rows[index],
                treeWidth: lanes * _laneWidth,
              ),
            );
          },
        ),
      ),
    );
  }
}

final class _ProphetRow extends StatelessWidget {
  const _ProphetRow({required this.row, required this.treeWidth, super.key});

  final LineageRow row;
  final double treeWidth;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    final prophet = row.prophet;
    final title = prophet.titleFor(languageCode);
    return InkWell(
      onTap: () => unawaited(
        context.pushNamed(
          Routes.prophet.name,
          pathParameters: {'id': prophet.id},
        ),
      ),
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
                  dotColor: q.primary,
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
                    style: QType.titleSm.copyWith(color: q.ink),
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
        ),
      ),
    );
  }
}
