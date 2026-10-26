import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/painters/qalb_mark.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_list_row.dart';
import '../../../notifications/domain/repositories/notification_scheduler.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/domain/usecases/regional_defaults.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';

/// First-launch flow (design §4.2): welcome → language → location →
/// madhab → method → notifications → bismillah. Re-enterable from
/// Settings ("Run setup again"). Every permission step has a skip path.
final class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({this.rerun = false, super.key});

  /// Opened from Settings over a finished setup: closable at any step.
  final bool rerun;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

final class _OnboardingScreenState extends State<OnboardingScreen> {
  late final SettingsStore _settings = locator<SettingsStore>();
  late final NotificationScheduler _scheduler =
      locator<NotificationScheduler>();
  final PageController _pages = PageController();
  int _step = 0;

  static const _stepCount = 7;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int step) {
    setState(() => _step = step);
    unawaited(
      _pages.animateToPage(step, duration: QMotion.med, curve: QMotion.ease),
    );
  }

  Future<void> _allowNotifications() async {
    final status = await _scheduler.requestPermission();
    if (!mounted) {
      return;
    }
    if (status == NotificationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.onboardingNotifDenied)),
      );
    }
    _go(_step + 1);
  }

  Future<void> _finish() async {
    await _settings.setSetupComplete(complete: true);
    if (mounted) {
      context.goNamed(Routes.home.name);
    }
  }

  /// Set once the user picks a madhab, so the region default never
  /// overrides an explicit choice.
  var _madhabChosen = false;

  /// Leaving the location step: pre-select the region's default madhab,
  /// unless the user already chose one or changed it from the app default.
  Future<void> _applyRegionalMadhab() async {
    if (_madhabChosen ||
        _settings.prayerParams.value.madhab != const PrayerParams().madhab) {
      return;
    }
    await _settings.setMadhab(
      defaultMadhabFor(countryCodeOf(_settings.location.value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final materialL10n = MaterialLocalizations.of(context);
    // System back steps back through the flow instead of leaving it.
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _go(_step - 1);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  QSpace.s1,
                  QSpace.s2,
                  QSpace.s4,
                  QSpace.s2,
                ),
                child: Row(
                  children: [
                    if (_step > 0)
                      IconButton(
                        tooltip: materialL10n.backButtonTooltip,
                        icon: const BackButtonIcon(),
                        onPressed: () => _go(_step - 1),
                      )
                    else if (widget.rerun)
                      IconButton(
                        tooltip: materialL10n.closeButtonTooltip,
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    else
                      const SizedBox(width: QSpace.s3),
                    for (var i = 0; i < _stepCount; i++)
                      Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i <= _step ? q.primary : q.surface2,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _welcome(),
                    _language(),
                    _location(),
                    _madhab(),
                    _method(),
                    _notifications(),
                    _finishStep(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _frame({
    required String title,
    String? note,
    required Widget child,
    required Widget actions,
  }) {
    final q = context.q;
    return Padding(
      padding: const EdgeInsets.all(QSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: QType.headline.copyWith(color: q.ink)),
          if (note != null) ...[
            const SizedBox(height: QSpace.s2),
            Text(note, style: QType.body.copyWith(color: q.ink2)),
          ],
          const SizedBox(height: QSpace.s5),
          Expanded(child: child),
          const SizedBox(height: QSpace.s4),
          actions,
        ],
      ),
    );
  }

  Widget _nextButton({VoidCallback? onTap, String? label}) => QButton(
    label: label ?? context.l10n.next,
    expand: true,
    onPressed: onTap ?? () => _go(_step + 1),
  );

  Widget _welcome() => _frame(
    title: context.l10n.onboardingWelcomeTitle,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          QalbMark(
            size: 120,
            color: context.q.primary,
            accent: context.q.primary,
          ),
          const SizedBox(height: QSpace.s6),
          Text(
            context.l10n.onboardingWelcomeBody,
            textAlign: TextAlign.center,
            style: QType.body.copyWith(color: context.q.ink2),
          ),
        ],
      ),
    ),
    actions: _nextButton(),
  );

  Widget _language() => _frame(
    title: context.l10n.onboardingLanguageTitle,
    child: SignalBuilder(
      builder: (context) {
        final current = _settings.settings.value.localeCode;
        return Column(
          children: [
            for (final (code, label) in const [
              ('en', 'English'),
              ('bn', 'বাংলা'),
            ])
              QListRow(
                icon: Icons.translate,
                title: label,
                trailing: current == code
                    ? Icon(Icons.check_circle, color: context.q.primary)
                    : null,
                onTap: () => unawaited(_settings.setLocale(code)),
              ),
          ],
        );
      },
    ),
    actions: _nextButton(),
  );

  Widget _location() => _frame(
    title: context.l10n.onboardingLocationTitle,
    child: SignalBuilder(
      builder: (context) {
        final location = _settings.location.value;
        return Column(
          children: [
            QCard(
              padding: const EdgeInsets.symmetric(
                horizontal: QSpace.s4,
                vertical: QSpace.s2,
              ),
              child: QListRow(
                icon: Icons.place_outlined,
                title: location?.displayName.isNotEmpty ?? false
                    ? location!.displayName
                    : context.l10n.settingLocationNotSet,
                subtitle: context.l10n.locationPrimingBody,
                trailing: Icon(Icons.chevron_right, color: context.q.ink3),
                onTap: () => context.pushNamed(Routes.locationPicker.name),
              ),
            ),
          ],
        );
      },
    ),
    actions: SignalBuilder(
      builder: (context) => _nextButton(
        onTap: _settings.location.value == null
            ? () => context.pushNamed(Routes.locationPicker.name)
            : () {
                unawaited(_applyRegionalMadhab());
                _go(_step + 1);
              },
      ),
    ),
  );

  Widget _madhab() => _frame(
    title: context.l10n.onboardingMadhabTitle,
    note: context.l10n.onboardingMadhabNote,
    child: SignalBuilder(
      builder: (context) {
        final current = _settings.prayerParams.value.madhab;
        return Column(
          children: [
            for (final madhab in Madhab.values)
              QListRow(
                icon: Icons.balance_outlined,
                title: context.l10n.madhabLabel(madhab),
                trailing: current == madhab
                    ? Icon(Icons.check_circle, color: context.q.primary)
                    : null,
                onTap: () {
                  _madhabChosen = true;
                  unawaited(_settings.setMadhab(madhab));
                },
              ),
          ],
        );
      },
    ),
    actions: _nextButton(),
  );

  Widget _method() => _frame(
    title: context.l10n.onboardingMethodTitle,
    note: context.l10n.onboardingMethodNote,
    child: SignalBuilder(
      builder: (context) {
        final current = _settings.prayerParams.value.method;
        final suggested = suggestedMethodFor(
          countryCodeOf(_settings.location.value),
        );
        final ordered = [
          suggested,
          for (final m in CalculationMethodId.values)
            if (m != suggested) m,
        ];
        return ListView(
          children: [
            for (final method in ordered)
              QListRow(
                icon: Icons.functions_outlined,
                title: context.l10n.methodLabel(method),
                trailing: current == method
                    ? Icon(Icons.check_circle, color: context.q.primary)
                    : null,
                onTap: () => unawaited(_settings.setMethod(method)),
              ),
          ],
        );
      },
    ),
    actions: _nextButton(),
  );

  Widget _notifications() => _frame(
    title: context.l10n.onboardingNotifTitle,
    child: Column(
      children: [
        QBanner(
          text: context.l10n.onboardingNotifBody,
          icon: Icons.notifications_active_outlined,
        ),
      ],
    ),
    actions: Column(
      children: [
        _nextButton(
          label: context.l10n.onboardingNotifAllow,
          onTap: () => unawaited(_allowNotifications()),
        ),
        const SizedBox(height: QSpace.s2),
        QButton(
          label: context.l10n.onboardingNotifSkip,
          kind: QButtonKind.ghost,
          expand: true,
          onPressed: () => _go(_step + 1),
        ),
      ],
    ),
  );

  Widget _finishStep() => _frame(
    title: context.l10n.onboardingFinishTitle,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          QalbMark(
            color: context.q.accentStrong,
            accent: context.q.accentStrong,
          ),
          const SizedBox(height: QSpace.s5),
          Text(
            context.l10n.onboardingFinishBody,
            textAlign: TextAlign.center,
            style: QType.body.copyWith(color: context.q.ink2),
          ),
        ],
      ),
    ),
    actions: _nextButton(
      label: context.l10n.onboardingBegin,
      onTap: () => unawaited(_finish()),
    ),
  );
}
