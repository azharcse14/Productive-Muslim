import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_celebrate.dart';
import '../../../../shared/widgets/q_chip.dart';
import '../../../../shared/widgets/q_number_dialog.dart';
import '../../../../shared/widgets/q_progress_ring.dart';
import '../../../keep_awake/domain/screen_wake.dart';
import '../state/tasbih_store.dart';

const _presets = [33, 100];

/// Standard short dhikr phrases: l10n id (transliteration) → Arabic.
const _phrases = {
  'subhanallah': 'سُبْحَانَ ٱللَّٰهِ',
  'alhamdulillah': 'ٱلْحَمْدُ لِلَّٰهِ',
  'allahuakbar': 'ٱللَّٰهُ أَكْبَرُ',
  'tahlil': 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ',
  'astaghfirullah': 'أَسْتَغْفِرُ ٱللَّٰهَ',
};

/// The after-prayer tasbih: one 100-bead round, the phrase advancing at
/// each boundary (33 SubhanAllah, 33 Alhamdulillah, 34 Allahu Akbar).
const _afterSalahId = 'after_salah';
const _afterSalahSteps = [
  ('subhanallah', 33),
  ('alhamdulillah', 33),
  ('allahuakbar', 34),
];
const _afterSalahTotal = 100;

/// The after-salah step for [count]: (phrase id, beads into the step, step
/// size). Past the end it stays on the last step, full.
(String, int, int) afterSalahStep(int count) {
  var start = 0;
  for (final (id, size) in _afterSalahSteps) {
    if (count < start + size) {
      return (id, count - start, size);
    }
    start += size;
  }
  final (id, size) = _afterSalahSteps.last;
  return (id, size, size);
}

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
  late final ScreenWake _wake = locator<ScreenWake>();

  /// A [_phrases] id or [_afterSalahId] (persisted by the store); an
  /// unknown stored id falls back to the first phrase.
  String get _phraseId => switch (_store.phrase.value) {
    final id? when id == _afterSalahId || _phrases.containsKey(id) => id,
    _ => _phrases.keys.first,
  };

  /// After-salah mode only holds while the round is the 100-bead one (the
  /// target can also change from the Home quick card).
  bool get _afterSalah =>
      _phraseId == _afterSalahId && _store.target.value == _afterSalahTotal;

  /// Keeps "Today: N counted" on the right day while the screen stays open
  /// past midnight.
  Timer? _dayTick;

  @override
  void initState() {
    super.initState();
    unawaited(_store.load());
    // Counting with the phone set down: don't let the screen lock.
    unawaited(_wake.hold(on: true));
    _dayTick = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _store.rollOverDay(),
    );
  }

  @override
  void dispose() {
    _dayTick?.cancel();
    unawaited(_wake.hold(on: false));
    super.dispose();
  }

  void _setPhrase(String id) => unawaited(_store.setPhrase(id));

  /// A new dhikr mid-round would carry the old phrase's beads over: ask to
  /// save or discard the round first (cancel keeps the phrase).
  Future<void> _pickPhrase(String id) async {
    if (id == _phraseId) {
      return;
    }
    if (_store.count.value > 0 && !await confirmTasbihReset(context, _store)) {
      return;
    }
    _setPhrase(id);
  }

  /// Like [_pickPhrase]: a mode change that would reinterpret the round's
  /// beads (into or out of after-salah, or a target below the count) asks to
  /// save or discard the round first. False on cancel.
  Future<bool> _confirmModeChange({
    required bool afterSalah,
    required int target,
  }) async {
    final count = _store.count.value;
    if (count == 0 || (afterSalah == _afterSalah && target >= count)) {
      return true;
    }
    return confirmTasbihReset(context, _store);
  }

  Future<void> _startAfterSalah() async {
    if (_afterSalah ||
        !await _confirmModeChange(afterSalah: true, target: _afterSalahTotal)) {
      return;
    }
    _setPhrase(_afterSalahId);
    _store.setTarget(_afterSalahTotal);
  }

  Future<void> _setTarget(int target) async {
    if (!await _confirmModeChange(afterSalah: false, target: target)) {
      return;
    }
    if (_phraseId == _afterSalahId) {
      _setPhrase(_phrases.keys.first);
    }
    _store.setTarget(target);
  }

  void _tap() {
    _store.tap();
    // Mark each phrase change; the store marks the final target itself.
    final count = _store.count.value;
    if (_afterSalah && count < _afterSalahTotal) {
      final (_, into, _) = afterSalahStep(count);
      if (into == 0) {
        Haptics.medium();
      }
    }
  }

  Future<void> _pickCustomTarget() async {
    final l10n = context.l10n;
    final picked = await showNumberDialog(
      context,
      title: l10n.tasbihTarget,
      hint: l10n.tasbihTargetInvalid,
      actionLabel: l10n.save,
      initial: _presets.contains(_store.target.value)
          ? null
          : _store.target.value,
    );
    if (picked != null && mounted) {
      await _setTarget(picked);
    }
  }

  Future<void> _confirmReset() => confirmTasbihReset(context, _store);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tasbihTitle),
        actions: [
          SignalBuilder(
            builder: (context) {
              final on = _store.autoNextRound.value;
              return IconButton(
                tooltip: l10n.tasbihAutoNext,
                isSelected: on,
                icon: Icon(on ? Icons.repeat_on : Icons.repeat),
                onPressed: () => unawaited(_store.setAutoNextRound(value: !on)),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final count = _store.count.value;
            final target = _store.target.value;
            final reached = count >= target;
            final afterSalah = _afterSalah;
            final step = afterSalah ? afterSalahStep(count) : null;
            final phraseId = step?.$1 ?? _phraseId;
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
                        style: context.text.labelSmall?.copyWith(color: q.ink2),
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
                              active: !afterSalah && target == preset,
                              onTap: () => unawaited(_setTarget(preset)),
                            ),
                          QChip(
                            label: _presets.contains(target)
                                ? l10n.tasbihCustom
                                : LocaleDigits.localize(
                                    '$target',
                                    languageCode,
                                  ),
                            active: !afterSalah && !_presets.contains(target),
                            onTap: () => unawaited(_pickCustomTarget()),
                          ),
                          QChip(
                            label: l10n.tasbihAfterSalah,
                            active: afterSalah,
                            onTap: () => unawaited(_startAfterSalah()),
                          ),
                        ],
                      ),
                      if (!afterSalah) ...[
                        const SizedBox(height: QSpace.s3),
                        Text(
                          l10n.tasbihDhikr.toUpperCase(),
                          style: context.text.labelSmall?.copyWith(
                            color: q.ink2,
                          ),
                        ),
                        const SizedBox(height: QSpace.s2),
                        // One scrolling line, so the counter keeps its room.
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            spacing: QSpace.s2,
                            children: [
                              for (final id in _phrases.keys)
                                QChip(
                                  label: l10n.tasbihPhrase(id),
                                  active: phraseId == id,
                                  onTap: () => unawaited(_pickPhrase(id)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // The daily-touch surface: everything below the presets
                // counts a bead.
                Expanded(
                  child: Semantics(
                    button: true,
                    liveRegion: true,
                    label:
                        '${l10n.tasbihTitle}, ${l10n.tasbihPhrase(phraseId)}',
                    // The count against its target, and the reached note.
                    value: [
                      LocaleDigits.localize('$count / $target', languageCode),
                      if (reached) l10n.tasbihTargetReached,
                    ].join(', '),
                    onTap: _tap,
                    child: ExcludeSemantics(
                      // Ripple from the touch point as bead feedback; no
                      // double-tap recognizer, so rapid taps each count.
                      child: InkWell(
                        onTap: _tap,
                        highlightColor: Colors.transparent,
                        splashFactory: reduced
                            ? NoSplash.splashFactory
                            : InkRipple.splashFactory,
                        // The 240dp ring shrinks to fit short screens.
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _phrases[phraseId]!,
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: QType.quran(30).copyWith(color: q.ink),
                                ),
                                Text(
                                  l10n.tasbihPhrase(phraseId),
                                  style: QType.label.copyWith(color: q.ink2),
                                ),
                                if (step != null)
                                  Text(
                                    l10n.tasbihStepProgress(
                                      LocaleDigits.localize(
                                        '${step.$2}',
                                        languageCode,
                                      ),
                                      LocaleDigits.localize(
                                        '${step.$3}',
                                        languageCode,
                                      ),
                                    ),
                                    style: QType.caption.copyWith(
                                      color: q.ink3,
                                    ),
                                  ),
                                const SizedBox(height: QSpace.s4),
                                QCelebrate(
                                  active: reached,
                                  child: QProgressRing(
                                    progress: target == 0 ? 0 : count / target,
                                    size: 240,
                                    strokeWidth: 12,
                                    color: reached ? q.accentStrong : q.primary,
                                    child: Text(
                                      LocaleDigits.localize(
                                        '$count',
                                        languageCode,
                                      ),
                                      // Digits only: tabular so the count
                                      // doesn't jitter as it climbs.
                                      style: QType.countdown.copyWith(
                                        color: q.ink,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: QSpace.s5),
                                AnimatedScale(
                                  scale: reached ? 1 : 0.85,
                                  duration: reduced
                                      ? Duration.zero
                                      : QMotion.slow,
                                  curve: QMotion.ease,
                                  child: Opacity(
                                    opacity: reached ? 1 : 0,
                                    child: Text(
                                      l10n.tasbihTargetReached,
                                      textAlign: TextAlign.center,
                                      style: QType.label.copyWith(
                                        color: q.accentStrong,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          QButton(
                            label: l10n.tasbihReset,
                            kind: QButtonKind.outline,
                            small: true,
                            onPressed: count > 0
                                ? () => unawaited(_confirmReset())
                                : null,
                          ),
                          const SizedBox(width: QSpace.s2),
                          IconButton(
                            tooltip: l10n.tasbihUndo,
                            onPressed: count > 0 ? _store.undo : null,
                            icon: const Icon(Icons.undo),
                          ),
                        ],
                      ),
                      const SizedBox(height: QSpace.s3),
                      Text(
                        LocaleDigits.localize(
                          l10n.tasbihSessionLine(_store.countedToday),
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

/// Save-and-reset confirmation shared by this screen and the Home quick
/// card, so a stray tap never ends a round silently. True when the round
/// was ended (saved or discarded), false on cancel.
Future<bool> confirmTasbihReset(BuildContext context, TasbihStore store) async {
  final l10n = context.l10n;
  // null = cancel, false = discard the round, true = save it.
  final save = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.tasbihReset),
      content: Text(l10n.tasbihResetConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.tasbihDiscard),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  if (save == null) {
    return false;
  }
  await store.reset(saveToHistory: save);
  return true;
}
