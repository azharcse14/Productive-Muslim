import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_progress_ring.dart';
import '../../../../shared/widgets/q_seg_control.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../domain/entities/asma_quiz.dart';
import '../state/asma_quiz_store.dart';
import '../state/dua_store.dart';

/// Self-test over the 99 names: pick the right meaning for a name (or the
/// right name for a meaning). No audio. Encouraging, no-shame results.
final class AsmaQuizScreen extends StatefulWidget {
  const AsmaQuizScreen({super.key});

  @override
  State<AsmaQuizScreen> createState() => _AsmaQuizScreenState();
}

final class _AsmaQuizScreenState extends State<AsmaQuizScreen> {
  // App-scoped catalogue store; the quiz store is screen-scoped (a factory).
  late final DuaStore _names = locator<DuaStore>();
  late final AsmaQuizStore _quiz = locator<AsmaQuizStore>();

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  Future<void> _boot() async {
    if (!_names.loaded.value) {
      await _names.load();
    }
    await _quiz.load();
    await _quiz.start(_names.asma.value);
  }

  Future<void> _retry() async {
    await _names.load();
    await _quiz.start(_names.asma.value);
  }

  Future<void> _onSelectMode(int i) async {
    final mode = AsmaQuizMode.values[i];
    if (mode == _quiz.mode.value) {
      return;
    }
    // Switching restarts the run, so don't throw away answers silently.
    final started = _quiz.index.value > 0 || _quiz.answered.value;
    if (started && !(await _confirmModeSwitch())) {
      return;
    }
    await _quiz.start(_names.asma.value, mode: mode);
  }

  Future<bool> _confirmModeSwitch() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.asmaQuizSwitchModeTitle),
        content: Text(l10n.asmaQuizSwitchModeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.asmaQuizSwitchMode),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _onAnswer(int i) {
    final question = _quiz.current.value;
    if (question == null || _quiz.answered.value) {
      return;
    }
    _quiz.answer(i);
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final answer = question.options[question.answerIndex];
    final message = question.isCorrect(i)
        ? l10n.asmaQuizCorrect
        : l10n.asmaQuizWrongAnswerIs(
            question.mode == AsmaQuizMode.meaningToName
                ? answer.transliteration
                : answer.meaningFor(languageCode),
          );
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }

  void _onNext() => unawaited(_quiz.next());

  void _onRestart() => _quiz.restart(_names.asma.value);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.asmaQuizTitle)),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final questions = _quiz.questions.value;
            if (questions.isEmpty) {
              // Loaded but no names: the asset failed, don't spin forever.
              if (_names.loaded.value && _names.asma.value.isEmpty) {
                return QErrorRetry(
                  message: l10n.asmaLoadError,
                  retryLabel: l10n.hadithRetry,
                  onRetry: () => unawaited(_retry()),
                );
              }
              return const QSkeletonList(count: 5, height: 72);
            }
            if (_quiz.finished.value) {
              return _ResultView(
                score: _quiz.score.value,
                total: questions.length,
                best: _quiz.best.value,
                onRestart: _onRestart,
              );
            }
            return _QuestionView(
              question: _quiz.current.value!,
              index: _quiz.index.value,
              total: questions.length,
              selected: _quiz.selected.value,
              answered: _quiz.answered.value,
              modeIndex: AsmaQuizMode.values.indexOf(_quiz.mode.value),
              onSelectMode: (i) => unawaited(_onSelectMode(i)),
              onAnswer: _onAnswer,
              onNext: _onNext,
            );
          },
        ),
      ),
    );
  }
}

final class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.question,
    required this.index,
    required this.total,
    required this.selected,
    required this.answered,
    required this.modeIndex,
    required this.onSelectMode,
    required this.onAnswer,
    required this.onNext,
  });

  final AsmaQuestion question;
  final int index;
  final int total;
  final int? selected;
  final bool answered;
  final int modeIndex;
  final ValueChanged<int> onSelectMode;
  final ValueChanged<int> onAnswer;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    final showMeaningAsPrompt = question.mode == AsmaQuizMode.meaningToName;
    final promptText = showMeaningAsPrompt
        ? question.prompt.meaningFor(languageCode)
        : question.prompt.arabic;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        QSpace.s5,
        QSpace.s3,
        QSpace.s5,
        QSpace.s5,
      ),
      children: [
        QSegControl(
          options: [
            l10n.asmaQuizModeNameToMeaning,
            l10n.asmaQuizModeMeaningToName,
          ],
          activeIndex: modeIndex,
          onChanged: onSelectMode,
        ),
        const SizedBox(height: QSpace.s4),
        Row(
          children: [
            QProgressRing(
              progress: total == 0 ? 0 : (index + 1) / total,
              size: 44,
              strokeWidth: 5,
            ),
            const SizedBox(width: QSpace.s3),
            Text(
              LocaleDigits.localize(
                l10n.asmaQuizProgress(index + 1, total),
                languageCode,
              ),
              style: QType.titleSm.copyWith(color: q.ink),
            ),
          ],
        ),
        const SizedBox(height: QSpace.s4),
        QCard(
          padding: const EdgeInsets.symmetric(
            horizontal: QSpace.s5,
            vertical: QSpace.s6,
          ),
          child: Column(
            children: [
              Text(
                showMeaningAsPrompt
                    ? l10n.asmaQuizPromptName
                    : l10n.asmaQuizPromptMeaning,
                textAlign: TextAlign.center,
                style: QType.caption.copyWith(color: q.ink2),
              ),
              const SizedBox(height: QSpace.s3),
              Text(
                promptText,
                textAlign: TextAlign.center,
                textDirection: showMeaningAsPrompt ? null : TextDirection.rtl,
                style: showMeaningAsPrompt
                    ? QType.title.copyWith(color: q.ink)
                    : QType.quran(40).copyWith(color: q.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: QSpace.s5),
        for (final (i, option) in question.options.indexed) ...[
          _OptionTile(
            label: showMeaningAsPrompt
                ? option.transliteration
                : option.meaningFor(languageCode),
            // The name itself alongside its transliteration.
            arabic: showMeaningAsPrompt ? option.arabic : null,
            isCorrect: i == question.answerIndex,
            isSelected: i == selected,
            answered: answered,
            onTap: answered ? null : () => onAnswer(i),
          ),
          const SizedBox(height: QSpace.s3),
        ],
        const SizedBox(height: QSpace.s2),
        if (answered)
          QButton(
            label: index + 1 >= total
                ? l10n.asmaQuizSeeResult
                : l10n.asmaQuizNext,
            icon: Icons.arrow_forward,
            expand: true,
            onPressed: onNext,
          ),
      ],
    );
  }
}

/// A tappable answer. After [answered], the correct option turns ok-green and
/// a wrongly-picked option turns urgent-red — colors come from theme tokens.
final class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    this.arabic,
    required this.isCorrect,
    required this.isSelected,
    required this.answered,
    required this.onTap,
  });

  final String label;
  final String? arabic;
  final bool isCorrect;
  final bool isSelected;
  final bool answered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final reduced = MediaQuery.disableAnimationsOf(context);

    final (Color bg, Color border, Color fg, IconData? mark) = switch ((
      answered,
      isCorrect,
      isSelected,
    )) {
      (true, true, _) => (q.okSoft, q.ok, q.ink, Icons.check_circle_outline),
      (true, false, true) => (
        q.urgentSoft,
        q.urgent,
        q.ink,
        Icons.cancel_outlined,
      ),
      _ => (q.surface, q.line, q.ink, null),
    };

    final l10n = context.l10n;
    return Semantics(
      button: true,
      selected: isSelected,
      label: switch ((answered, isCorrect, isSelected)) {
        (true, true, _) => l10n.asmaQuizCorrectOption(label),
        (true, false, true) => l10n.asmaQuizWrongOption(label),
        _ => label,
      },
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: reduced ? Duration.zero : QMotion.fast,
          curve: QMotion.ease,
          constraints: const BoxConstraints(minHeight: QTouch.minTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: QSpace.s4,
            vertical: QSpace.s3,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(QRadius.md),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: QType.titleSm.copyWith(color: fg)),
              ),
              if (arabic != null) ...[
                const SizedBox(width: QSpace.s2),
                Text(
                  arabic!,
                  textDirection: TextDirection.rtl,
                  style: QType.quran(22).copyWith(color: fg),
                ),
              ],
              if (mark != null) ...[
                const SizedBox(width: QSpace.s2),
                Icon(mark, size: 20, color: border),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.score,
    required this.total,
    required this.best,
    required this.onRestart,
  });

  final int score;
  final int total;
  final int best;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    final ratio = total == 0 ? 0.0 : score / total;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(QSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QProgressRing(
              progress: ratio,
              size: 132,
              child: Text(
                LocaleDigits.localize(
                  l10n.asmaQuizScore(score, total),
                  languageCode,
                ),
                style: QType.num_(QType.title).copyWith(color: q.ink),
              ),
            ),
            const SizedBox(height: QSpace.s5),
            Text(
              l10n.asmaQuizResultTitle,
              textAlign: TextAlign.center,
              style: QType.headline.copyWith(color: q.ink),
            ),
            const SizedBox(height: QSpace.s2),
            Text(
              l10n.asmaQuizResultEncouragement,
              textAlign: TextAlign.center,
              style: QType.body.copyWith(color: q.ink2),
            ),
            const SizedBox(height: QSpace.s4),
            Text(
              LocaleDigits.localize(l10n.asmaQuizBest(best), languageCode),
              style: QType.caption.copyWith(color: q.ink2),
            ),
            const SizedBox(height: QSpace.s6),
            QButton(
              label: l10n.asmaQuizPlayAgain,
              icon: Icons.refresh,
              expand: true,
              onPressed: onRestart,
            ),
          ],
        ),
      ),
    );
  }
}
