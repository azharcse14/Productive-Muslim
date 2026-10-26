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
import '../../../onboarding/presentation/screens/lock_screen.dart';
import '../../../onboarding/presentation/state/app_lock_store.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/prayer_params.dart';
import '../state/settings_store.dart';
import '../widgets/option_sheet.dart';
import '../widgets/setting_labels.dart';

/// Grouped settings (design §12): calculation / notifications /
/// appearance & language / privacy / about. Notification matrix UI lands
/// in Phase 4; app lock in Phase 11.
final class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

final class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsStore _store = locator<SettingsStore>();

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
                        label: l10n.settingSahriSafety,
                        onChanged: _store.setSahriSafety,
                      ),
                    ),
                    const Divider(),
                    QListRow(
                      icon: Icons.nightlight_outlined,
                      title: l10n.settingHijriOffset,
                      subtitle: l10n.settingHijriOffsetSub,
                      trailing: _AdjustmentStepper(
                        key: const ValueKey('hijri-offset-stepper'),
                        value: settings.hijriOffsetDays,
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
                child: QListRow(
                  icon: Icons.info_outline,
                  title: l10n.settingCredits,
                  subtitle: l10n.creditsBody,
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
      await lock.disable();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => const LockScreen(mode: LockScreenMode.setup),
      ),
    );
  }

  Future<void> _runSetupAgain() async {
    await _store.setSetupComplete(complete: false);
    if (mounted) {
      context.goNamed(Routes.onboarding.name);
    }
  }

  Future<void> _pickMadhab(Madhab current) async {
    final l10n = context.l10n;
    final choice = await showOptionSheet(
      context: context,
      title: l10n.settingMadhab,
      options: Madhab.values,
      selected: current,
      labelOf: l10n.madhabLabel,
      sublabelOf: (_) => l10n.madhabExplain,
    );
    if (choice != null) {
      await _store.setMadhab(choice);
    }
  }

  Future<void> _pickMethod(CalculationMethodId current) async {
    final l10n = context.l10n;
    final choice = await showOptionSheet(
      context: context,
      title: l10n.settingMethod,
      options: CalculationMethodId.values,
      selected: current,
      labelOf: l10n.methodLabel,
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

  Future<void> _editAdjustments() async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
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
                          _AdjustmentStepper(
                            value: params.adjustmentFor(prayer),
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
    required this.label,
    required this.onChanged,
    this.format,
    super.key,
  });

  final int value;

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
            onTap: () => onChanged(value - 1),
          ),
          SizedBox(
            width: format == null ? 56 : 72,
            child: Text(
              format?.call(value) ?? l10n.minutesShort(value),
              textAlign: TextAlign.center,
              style: QType.num_(QType.label).copyWith(color: q.ink),
            ),
          ),
          QStepButton(
            icon: Icons.add,
            semanticLabel: l10n.a11yIncrease(label),
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

