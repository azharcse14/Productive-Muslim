import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_chip.dart';
import '../../../../shared/widgets/q_progress_ring.dart';
import '../state/tasbih_store.dart';

const _presets = [33, 100];

/// Full-screen tactile counter: the whole lower area is one big tap target
/// around the progress ring. Daily-touch surface — keep it calm.
final class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

final class _TasbihScreenState extends State<TasbihScreen> {
  // App-scoped store — never disposed here.
  late final TasbihStore _store = locator<TasbihStore>();

  @override
  void initState() {
    super.initState();
    unawaited(_store.load());
  }

  Future<void> _pickCustomTarget() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => const _CustomTargetDialog(),
    );
    if (picked != null) {
      _store.setTarget(picked);
    }
  }

  Future<void> _confirmReset() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tasbihReset),
        content: Text(l10n.tasbihResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _store.reset(saveToHistory: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tasbihTitle)),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final count = _store.count.value;
            final target = _store.target.value;
            final reached = count >= target;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    QSpace.s5,
                    QSpace.s3,
                    QSpace.s5,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tasbihTarget.toUpperCase(),
                        style: QType.overline.copyWith(color: q.ink2),
                      ),
                      const SizedBox(height: QSpace.s2),
                      Wrap(
                        spacing: QSpace.s2,
                        runSpacing: QSpace.s2,
                        children: [
                          for (final preset in _presets)
                            QChip(
                              label: LocaleDigits.localize(
                                '$preset',
                                languageCode,
                              ),
                              active: target == preset,
                              onTap: () => _store.setTarget(preset),
                            ),
                          QChip(
                            label: _presets.contains(target)
                                ? l10n.tasbihCustom
                                : LocaleDigits.localize(
                                    '$target',
                                    languageCode,
                                  ),
                            active: !_presets.contains(target),
                            onTap: () => unawaited(_pickCustomTarget()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // The daily-touch surface: everything below the presets
                // counts a bead.
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _store.tap,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        QProgressRing(
                          progress: target == 0 ? 0 : count / target,
                          size: 240,
                          strokeWidth: 12,
                          color: reached ? q.accentStrong : q.primary,
                          child: Text(
                            LocaleDigits.localize('$count', languageCode),
                            style: QType.num_(QType.countdown)
                                .copyWith(color: q.ink),
                          ),
                        ),
                        const SizedBox(height: QSpace.s5),
                        AnimatedScale(
                          scale: reached ? 1 : 0.85,
                          duration: reduced ? Duration.zero : QMotion.slow,
                          curve: QMotion.ease,
                          child: Opacity(
                            opacity: reached ? 1 : 0,
                            child: Text(
                              l10n.tasbihTargetReached,
                              textAlign: TextAlign.center,
                              style: QType.label
                                  .copyWith(color: q.accentStrong),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    QSpace.s5,
                    0,
                    QSpace.s5,
                    QSpace.s5,
                  ),
                  child: Column(
                    children: [
                      QButton(
                        label: l10n.tasbihReset,
                        kind: QButtonKind.outline,
                        small: true,
                        onPressed:
                            count > 0 ? () => unawaited(_confirmReset()) : null,
                      ),
                      const SizedBox(height: QSpace.s3),
                      Text(
                        LocaleDigits.localize(
                          l10n.tasbihSessionLine(_store.totalToday.value),
                          languageCode,
                        ),
                        style: QType.caption.copyWith(color: q.ink2),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _CustomTargetDialog extends StatefulWidget {
  const _CustomTargetDialog();

  @override
  State<_CustomTargetDialog> createState() => _CustomTargetDialogState();
}

final class _CustomTargetDialogState extends State<_CustomTargetDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    Navigator.of(context).pop(value != null && value > 0 ? value : null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.tasbihTarget),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(hintText: l10n.tasbihCustom),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
