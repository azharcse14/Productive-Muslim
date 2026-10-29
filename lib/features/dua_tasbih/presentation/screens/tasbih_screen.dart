import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../../../../shared/widgets/q_progress_ring.dart';
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

  static const _phraseKey = 'tasbih_phrase';
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  /// A [_phrases] id or [_afterSalahId]; persisted.
  final _phrase = signal(_phrases.keys.first);

  /// After-salah mode only holds while the round is the 100-bead one (the
  /// target can also change from the Home quick card).
  bool get _afterSalah =>
      _phrase.value == _afterSalahId && _store.target.value == _afterSalahTotal;

  @override
  void initState() {
    super.initState();
    unawaited(_store.load());
    unawaited(_loadPhrase());
  }

  @override
  void dispose() {
    _phrase.dispose();
    super.dispose();
  }

  Future<void> _loadPhrase() async {
    final saved = await _prefs.getString(_phraseKey);
    if (mounted &&
        saved != null &&
        (saved == _afterSalahId || _phrases.containsKey(saved))) {
      _phrase.value = saved;
    }
  }

  void _setPhrase(String id) {
    _phrase.value = id;
    unawaited(_prefs.setString(_phraseKey, id));
  }

  void _startAfterSalah() {
    _setPhrase(_afterSalahId);
    _store.setTarget(_afterSalahTotal);
  }

  void _setTarget(int target) {
    if (_phrase.value == _afterSalahId) {
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
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => const _CustomTargetDialog(),
    );
    if (picked != null) {
      _setTarget(picked);
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
      appBar: AppBar(title: Text(l10n.tasbihTitle)),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final count = _store.count.value;
            final target = _store.target.value;
            final reached = count >= target;
            final afterSalah = _afterSalah;
            final step = afterSalah ? afterSalahStep(count) : null;
            final phraseId = step?.$1 ?? _phrase.value;
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
                              active: !afterSalah && target == preset,
                              onTap: () => _setTarget(preset),
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
                            onTap: _startAfterSalah,
                          ),
                        ],
                      ),
                      if (!afterSalah) ...[
                        const SizedBox(height: QSpace.s3),
                        Text(
                          l10n.tasbihDhikr.toUpperCase(),
                          style: QType.overline.copyWith(color: q.ink2),
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
                                  onTap: () => _setPhrase(id),
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
                    value: LocaleDigits.localize('$count', languageCode),
                    onTap: _tap,
                    child: ExcludeSemantics(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _tap,
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
                                      style: QType.num_(
                                        QType.countdown,
                                      ).copyWith(color: q.ink),
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

  /// Shown instead of closing silently on an empty/zero entry.
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    // Bengali/Arabic-Indic digits are typed on localized keyboards.
    final value = int.tryParse(LocaleDigits.toAscii(_controller.text));
    if (value == null || value < 1) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(value);
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
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[0-9০-৯٠-٩۰-۹]')),
          LengthLimitingTextInputFormatter(5),
        ],
        decoration: InputDecoration(
          hintText: l10n.tasbihCustom,
          errorText: _invalid ? l10n.tasbihTargetInvalid : null,
        ),
        onChanged: (_) {
          if (_invalid) {
            setState(() => _invalid = false);
          }
        },
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

/// Save-and-reset confirmation shared by this screen and the Home quick
/// card, so a stray tap never ends a round silently.
Future<void> confirmTasbihReset(BuildContext context, TasbihStore store) async {
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
  if (save != null) {
    await store.reset(saveToHistory: save);
  }
}
