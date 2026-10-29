import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_medallion.dart';
import '../../../../shared/widgets/q_pressable.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../domain/entities/dua.dart';
import '../state/dua_store.dart';

/// The 99 names of Allah: numbered medallion list; tap for a focused sheet
/// with the name large.
final class AsmaulHusnaScreen extends StatefulWidget {
  const AsmaulHusnaScreen({super.key});

  @override
  State<AsmaulHusnaScreen> createState() => _AsmaulHusnaScreenState();
}

final class _AsmaulHusnaScreenState extends State<AsmaulHusnaScreen> {
  // App-scoped store — never disposed here.
  late final DuaStore _store = locator<DuaStore>();

  @override
  void initState() {
    super.initState();
    if (!_store.loaded.value) {
      unawaited(_store.load());
    }
  }

  // QPressable already plays the selection haptic.
  Future<void> _showDetail(AsmaName name) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => _AsmaDetailSheet(name: name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.asmaulHusnaTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz_outlined),
            tooltip: l10n.asmaQuizTitle,
            onPressed: () => context.pushNamed(Routes.asmaQuiz.name),
          ),
        ],
      ),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final names = _store.asma.value;
            if (!_store.loaded.value) {
              return ListView(
                padding: const EdgeInsets.all(QSpace.s5),
                children: [
                  for (var i = 0; i < 8; i++) ...[
                    const QSkeleton(height: 48, radius: QRadius.sm),
                    const SizedBox(height: QSpace.s3),
                  ],
                ],
              );
            }
            if (_store.failed.value && names.isEmpty) {
              return QErrorRetry(
                message: l10n.asmaLoadError,
                retryLabel: l10n.hadithRetry,
                onRetry: () => unawaited(_store.load()),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                QSpace.s5,
                QSpace.s3,
                QSpace.s5,
                QSpace.s5,
              ),
              itemCount: names.length,
              itemBuilder: (context, index) {
                final name = names[index];
                return _AsmaRow(
                  name: name,
                  onTap: () => unawaited(_showDetail(name)),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

final class _AsmaRow extends StatelessWidget {
  const _AsmaRow({required this.name, required this.onTap});

  final AsmaName name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    // Same row anatomy as the surah index rows.
    return QPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(QRadius.md),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 2,
          vertical: QSpace.s2,
        ),
        child: Row(
          children: [
            QMedallion(number: name.number),
            const SizedBox(width: QSpace.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.transliteration,
                    style: QType.titleSm.copyWith(color: q.ink),
                  ),
                  Text(
                    name.meaningFor(languageCode),
                    style: QType.caption.copyWith(color: q.ink2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: QSpace.s3),
            Text(
              name.arabic,
              textDirection: TextDirection.rtl,
              // A non-Arabic TTS garbles raw Arabic glyphs.
              semanticsLabel: name.transliteration,
              style: QType.quran(22).copyWith(color: q.ink),
            ),
          ],
        ),
      ),
    );
  }
}

final class _AsmaDetailSheet extends StatelessWidget {
  const _AsmaDetailSheet({required this.name});

  final AsmaName name;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(QSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QMedallion(number: name.number, size: 48),
            const SizedBox(height: QSpace.s4),
            Text(
              name.arabic,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              // A non-Arabic TTS garbles raw Arabic glyphs.
              semanticsLabel: name.transliteration,
              style: QType.quran(36).copyWith(color: q.ink),
            ),
            const SizedBox(height: QSpace.s3),
            Text(
              name.transliteration,
              textAlign: TextAlign.center,
              style: QType.title.copyWith(color: q.ink),
            ),
            const SizedBox(height: QSpace.s2),
            Text(
              name.meaningFor(languageCode),
              textAlign: TextAlign.center,
              style: QType.body.copyWith(color: q.ink2),
            ),
          ],
        ),
      ),
    );
  }
}
