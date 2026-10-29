import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_list_row.dart';
import '../../../../shared/widgets/q_step_button.dart';
import '../../../nearby_mosques/domain/external_launcher.dart';
import '../../../notifications/domain/repositories/notification_scheduler.dart';
import '../../../onboarding/presentation/screens/lock_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../onboarding/presentation/state/app_lock_store.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/prayer_params.dart';
import '../../domain/usecases/regional_defaults.dart';
import '../state/settings_store.dart';
import '../widgets/option_sheet.dart';
import '../widgets/setting_labels.dart';

/// Grouped settings (design §12): calculation / notifications /
/// appearance & language / privacy / about. Notification matrix UI lands
/// in Phase 4; app lock in Phase 11.
/// Tanzil's terms ask apps using its Quran text to link to tanzil.net.
final _tanzilUrl = Uri.parse('https://tanzil.net');

final class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

final class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsStore _store = locator<SettingsStore>();

  /// Null until known (or when no scheduler is registered, e.g. tests).
  final _notifPermission = signal<NotificationPermission?>(null);
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Re-check on return from system settings.
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_refreshPermission()),
    );
    unawaited(_refreshPermission());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refreshPermission() async {
    if (!locator.isRegistered<NotificationScheduler>()) {
      return;
    }
    final status = await locator<NotificationScheduler>().permissionStatus();
    if (mounted) {
      _notifPermission.value = status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SignalBuilder(
        builder: (context) {
          final settings = _store.settings.value;
          final params = settings.prayerParams;
          return ListView(
            padding: const EdgeInsets.all(QSpace.s5),
            children: [
              _GroupHeader(l10n.groupCalculation),
              QCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: QSpace.s4,
                  vertical: QSpace.s1,
                ),
                child: Column(
                  children: [
                    QListRow(
                      icon: Icons.place_outlined,
                      title: l10n.settingLocation,
                      subtitle:
                          settings.location?.displayName.isNotEmpty ?? false
                          ? settings.location!.displayName
                          : l10n.settingLocationNotSet,
                      trailing: Icon(Icons.chevron_right, color: q.ink3),
                      onTap: () =>
                          context.pushNamed(Routes.locationPicker.name),
                    ),
                    const Divider(),
                    QListRow(
                      icon: Icons.balance_outlined,
                      title: l10n.settingMadhab,
                      subtitle: l10n.madhabLabel(params.madhab),
                      trailing: Icon(Icons.chevron_right, color: q.ink3),
                      onTap: () => _pickMadhab(params.madhab),
                    ),
                    const Divider(),
                    QListRow(
                      icon: Icons.functions_outlined,
                      title: l10n.settingMethod,
                      subtitle: l10n.methodLabel(params.method),
                      trailing: Icon(Icons.chevron_right, color: q.ink3),
                      onTap: () => _pickMethod(params.method),
                    ),
                    const Divider(),
                    QListRow(
                      icon: Icons.tune_outlined,
                      title: l10n.settingAdjustments,
                      subtitle: l10n.settingAdjustmentsSub,
                      trailing: Icon(Icons.chevron_right, color: q.ink3),
                      onTap: _editAdjustments,
                    ),
                    const Divider(),
                    QListRow(
                      icon: Icons.public_outlined,
                      title: l10n.settingHighLat,
                      subtitle: l10n.highLatLabel(params.highLatitudeRule),
                      trailing: Icon(Icons.chevron_right, color: q.ink3),
                      onTap: () => _pickHighLat(params.highLatitudeRule),
                    ),
                    const Divider(),
                    QListRow(
                      icon: Icons.nightlight_outlined,
                      title: l10n.settingSahriSafety,
                      subtitle: l10n.settingSahriSafetySub,
                      trailing: _AdjustmentStepper(
                        key: const ValueKey('sahri-safety-stepper'),
                        value: params.sahriSafetyMinutes,
                        min: 0,
                        max: PrayerParams.maxSahriSafety,
                        label: l10n.settingSahriSafety,
                        onChanged: _store.setSahriSafety,
                      ),
                    ),
                    const Divider(),
                    QListRow(
                      icon: Icons.calendar_month_outlined,
                      title: l10n.settingHijriOffset,
                      subtitle: l10n.settingHijriOffsetSub,
                      trailing: _AdjustmentStepper(
                        key: const ValueKey('hijri-offset-stepper'),
                        value: settings.hijriOffsetDays,
                        min: AppSettings.minHijriOffset,
                        max: AppSettings.maxHijriOffset,
                        label: l10n.settingHijriOffset,
                        format: (v) => l10n.hijriOffsetValue(
                          v.abs(),
                          v > 0 ? '+' : (v < 0 ? '−' : ''),
                        ),
                        onChanged: _store.setHijriOffset,
                      ),
                    ),
                  ],
                ),
              ),
              _GroupHeader(l10n.groupNotifications),
              QCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: QSpace.s4,
                  vertical: QSpace.s1,
                ),
                child: QListRow(
                  icon: Icons.notifications_outlined,
                  title: l10n.notifSettingsTitle,
                  subtitle:
                      _notifPermission.value == null ||
                          _notifPermission.value ==
                              NotificationPermission.granted
                      ? null
                      : l10n.notifOffInSystem,
                  trailing: Icon(Icons.chevron_right, color: q.ink3),
                  onTap: () =>
                      context.pushNamed(Routes.notificationSettings.name),
                ),
              ),
              _GroupHeader(l10n.groupAppearance),
              QCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: QSpace.s4,
                  vertical: QSpace.s1,
                ),
                child: Column(
                  children: [
                    QListRow(
                      icon: Icons.brightness_6_outlined,
                      title: l10n.settingTheme,
                      subtitle: l10n.themeLabel(settings.themeMode),
                      trailing: Icon(Icons.chevron_right, color: q.ink3),
                      onTap: () => _pickTheme(settings.themeMode),
                    ),
                    const Divider(),
                    QListRow(
                      icon: Icons.translate_outlined,
                      title: l10n.settingLanguage,
                      subtitle: settings.localeCode == 'bn'
                          ? 'বাংলা'
                          : 'English',
                      trailing: Icon(Icons.chevron_right, color: q.ink3),
                      onTap: () => _pickLocale(settings.localeCode),
                    ),
                    const Divider(),
                    QListRow(
                      icon: Icons.dashboard_customize_outlined,
                      title: l10n.settingHomeCards,
                      subtitle: l10n.settingHomeCardsSub,
                      trailing: Icon(Icons.chevron_right, color: q.ink3),
                      onTap: () => unawaited(_editHomeCards()),
                    ),
                  ],
                ),
              ),
              _GroupHeader(l10n.groupPrivacy),
              QCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: QSpace.s4,
                  vertical: QSpace.s1,
                ),
                child: Column(
                  children: [
                    SignalBuilder(
                      builder: (context) {
                        final lock = locator<AppLockStore>();
                        return QListRow(
                          icon: Icons.lock_outline,
                          title: l10n.appLockEnable,
                          subtitle: l10n.appLockEnableSub,
                          trailing: Switch(
                            value: lock.enabled.value,
                            onChanged: (v) => unawaited(_toggleAppLock(v)),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    QListRow(
                      icon: Icons.emoji_events_outlined,
                      title: l10n.settingShowAchievements,
                      subtitle: l10n.settingShowAchievementsSub,
                      trailing: Switch(
                        value: settings.showAchievements,
                        onChanged: (v) =>
                            unawaited(_store.setShowAchievements(show: v)),
                      ),
                    ),
                    const Divider(),
                    QListRow(
                      icon: Icons.vibration,
                      title: l10n.settingHaptics,
                      subtitle: l10n.settingHapticsSub,
                      trailing: Switch(
                        value: settings.hapticsEnabled,
                        onChanged: (v) =>
                            unawaited(_store.setHapticsEnabled(enabled: v)),
                      ),
                    ),
                    const Divider(),
                    QListRow(
                      icon: Icons.replay_outlined,
                      title: l10n.settingRunSetup,
                      trailing: Icon(Icons.chevron_right, color: q.ink3),
                      onTap: () => unawaited(_runSetupAgain()),
                    ),
                  ],
                ),
              ),
              _GroupHeader(l10n.groupAbout),
              QCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: QSpace.s4,
                  vertical: QSpace.s1,
                ),
                child: Column(
                  children: [
                    QListRow(
                      icon: Icons.menu_book_outlined,
                      title: l10n.creditsQuranText,
                      subtitle: l10n.creditsQuranTextLink,
                      trailing: Icon(Icons.open_in_new, color: q.ink3),
                      onTap: () => unawaited(
                        locator<ExternalLauncher>().launch(_tanzilUrl),
                      ),
                    ),
                    const Divider(),
                    QListRow(
                      icon: Icons.info_outline,
                      title: l10n.settingCredits,
                      subtitle: l10n.creditsBody,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: QSpace.s10),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleAppLock(bool enable) async {
    final lock = locator<AppLockStore>();
    if (!enable) {
      // Turning the lock off needs the PIN (or biometric) first.
      final verified = await Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (_) => const LockScreen(mode: LockScreenMode.verify),
        ),
      );
      if (verified ?? false) {
        await lock.disable();
      }
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => const LockScreen(mode: LockScreenMode.setup),
      ),
    );
  }

  /// Setup stays complete while re-running, so the flow can be closed
  /// part-way (each step saves as it goes).
  Future<void> _runSetupAgain() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OnboardingScreen(rerun: true),
      ),
    );
  }

  Future<void> _pickMadhab(Madhab current) async {
    final l10n = context.l10n;
    final choice = await showOptionSheet(
      context: context,
      title: l10n.settingMadhab,
      options: asrMadhabChoices,
      selected: asrMadhabOf(current),
      labelOf: l10n.madhabLabel,
      sublabelOf: (_) => l10n.madhabExplain,
    );
    // Re-picking "Standard" keeps a stored maliki/hanbali as is.
    if (choice != null && choice != asrMadhabOf(current)) {
      await _store.setMadhab(choice);
    }
  }

  Future<void> _pickMethod(CalculationMethodId current) async {
    final l10n = context.l10n;
    final suggested = suggestedMethodFor(countryCodeOf(_store.location.value));
    final choice = await showOptionSheet(
      context: context,
      title: l10n.settingMethod,
      options: CalculationMethodId.values,
      selected: current,
      labelOf: l10n.methodLabel,
      sublabelOf: (m) => m == suggested ? l10n.methodSuggested : null,
    );
    if (choice != null) {
      await _store.setMethod(choice);
    }
  }

  Future<void> _pickHighLat(HighLatitudeRule current) async {
    final l10n = context.l10n;
    final choice = await showOptionSheet(
      context: context,
      title: l10n.settingHighLat,
      options: HighLatitudeRule.values,
      selected: current,
      labelOf: l10n.highLatLabel,
    );
    if (choice != null) {
      await _store.setHighLatitudeRule(choice);
    }
  }

  Future<void> _pickTheme(AppThemeMode current) async {
    final l10n = context.l10n;
    final choice = await showOptionSheet(
      context: context,
      title: l10n.settingTheme,
      options: AppThemeMode.values,
      selected: current,
      labelOf: l10n.themeLabel,
    );
    if (choice != null) {
      await _store.setThemeMode(choice);
    }
  }

  Future<void> _pickLocale(String current) async {
    final choice = await showOptionSheet(
      context: context,
      title: context.l10n.settingLanguage,
      options: const ['en', 'bn'],
      selected: current,
      labelOf: (code) => code == 'bn' ? 'বাংলা' : 'English',
    );
    if (choice != null) {
      await _store.setLocale(choice);
    }
  }

  Future<void> _editHomeCards() async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(QSpace.s5),
          child: SignalBuilder(
            builder: (context) {
              final hidden = _store.settings.value.hiddenHomeCards;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingHomeCards,
                    style: QType.title.copyWith(color: sheetContext.q.ink),
                  ),
                  const SizedBox(height: QSpace.s2),
                  for (final card in HomeCard.values)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.homeCardLabel(card)),
                      value: !hidden.contains(card),
                      onChanged: (v) => unawaited(
                        _store.setHomeCardVisible(card, visible: v),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _editAdjustments() async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        // Scrolls on short screens / large text instead of overflowing.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(QSpace.s5),
          child: SignalBuilder(
            builder: (context) {
              final params = _store.settings.value.prayerParams;
              final q = sheetContext.q;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingAdjustments,
                    style: QType.title.copyWith(color: q.ink),
                  ),
                  const SizedBox(height: QSpace.s3),
                  for (final prayer in Prayer.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: QSpace.s1),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.prayerLabel(prayer),
                              style: QType.titleSm.copyWith(color: q.ink),
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.adjustmentReset(
                              l10n.prayerLabel(prayer),
                            ),
                            icon: const Icon(Icons.restart_alt),
                            color: q.ink2,
                            onPressed: params.adjustmentFor(prayer) == 0
                                ? null
                                : () => _store.setAdjustment(prayer, 0),
                          ),
                          _AdjustmentStepper(
                            value: params.adjustmentFor(prayer),
                            min: -PrayerParams.maxAdjustment,
                            max: PrayerParams.maxAdjustment,
                            label: l10n.prayerLabel(prayer),
                            onChanged: (v) => _store.setAdjustment(prayer, v),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      top: QSpace.s6,
      bottom: QSpace.s3,
      start: QSpace.s1,
    ),
    child: Text(title.toUpperCase(), style: context.text.labelSmall),
  );
}

final class _AdjustmentStepper extends StatelessWidget {
  const _AdjustmentStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
    this.format,
    super.key,
  });

  final int value;

  /// Inclusive bounds; the button at a bound is disabled.
  final int min;
  final int max;

  /// Setting name, woven into the +/- buttons' screen-reader labels.
  final String label;
  final ValueChanged<int> onChanged;

  /// Value text; defaults to minutes.
  final String Function(int)? format;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: q.surface2,
        borderRadius: BorderRadius.circular(QRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QStepButton(
            icon: Icons.remove,
            semanticLabel: l10n.a11yDecrease(label),
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          // Grows with long values / large text instead of clipping.
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: format == null ? 56 : 72),
            child: Text(
              format?.call(value) ?? l10n.minutesShort(value),
              textAlign: TextAlign.center,
              style: QType.num_(QType.label).copyWith(color: q.ink),
            ),
          ),
          QStepButton(
            icon: Icons.add,
            semanticLabel: l10n.a11yIncrease(label),
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
