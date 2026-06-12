import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/painters/qalb_mark.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_list_row.dart';
import '../../../notifications/domain/repositories/notification_scheduler.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';

/// First-launch flow (design §4.2): welcome → language → location →
/// madhab → method → notifications → bismillah. Re-enterable from
/// Settings ("Run setup again"). Every permission step has a skip path.
final class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

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
      _pages.animateToPage(
        step,
        duration: QMotion.med,
        curve: QMotion.ease,
      ),
    );
  }

  Future<void> _finish() async {
    await _settings.setSetupComplete(complete: true);
    if (mounted) {
      context.goNamed(Routes.home.name);
    }
  }

  /// Region-suggested calculation method from the selected city's country.
  CalculationMethodId _suggestedMethod() {
    final location = _settings.location.value;
    final country = switch (location?.displayName.split(', ').lastOrNull) {
      final c? when c.length == 2 => c,
      _ => '',
    };
    return switch (country) {
      'SA' || 'YE' || 'OM' => CalculationMethodId.ummAlQura,
      'AE' => CalculationMethodId.dubai,
      'QA' => CalculationMethodId.qatar,
      'KW' => CalculationMethodId.kuwait,
      'EG' || 'SD' || 'LY' => CalculationMethodId.egyptian,
      'BD' || 'PK' || 'IN' || 'AF' => CalculationMethodId.karachi,
      'SG' || 'MY' || 'ID' => CalculationMethodId.singapore,
      'TR' => CalculationMethodId.turkiye,
      'IR' => CalculationMethodId.tehran,
      'US' || 'CA' => CalculationMethodId.northAmerica,
      'GB' => CalculationMethodId.moonsightingCommittee,
      _ => CalculationMethodId.muslimWorldLeague,
    };
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(QSpace.s4),
              child: Row(
                children: [
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
        child: SignalBuilder(builder: (context) {
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
        }),
        actions: _nextButton(),
      );

  Widget _location() => _frame(
        title: context.l10n.onboardingLocationTitle,
        child: SignalBuilder(builder: (context) {
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
                  onTap: () =>
                      context.pushNamed(Routes.locationPicker.name),
                ),
              ),
            ],
          );
        }),
        actions: SignalBuilder(
          builder: (context) => _nextButton(
            onTap: _settings.location.value == null
                ? () => context.pushNamed(Routes.locationPicker.name)
                : () => _go(_step + 1),
          ),
        ),
      );

  Widget _madhab() => _frame(
        title: context.l10n.onboardingMadhabTitle,
        note: context.l10n.onboardingMadhabNote,
        child: SignalBuilder(builder: (context) {
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
                  onTap: () => unawaited(_settings.setMadhab(madhab)),
                ),
            ],
          );
        }),
        actions: _nextButton(),
      );

  Widget _method() => _frame(
        title: context.l10n.onboardingMethodTitle,
        note: context.l10n.onboardingMethodNote,
        child: SignalBuilder(builder: (context) {
          final current = _settings.prayerParams.value.method;
          final suggested = _suggestedMethod();
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
        }),
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
              onTap: () => unawaited(
                _scheduler
                    .requestPermission()
                    .then((_) => _go(_step + 1)),
              ),
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
