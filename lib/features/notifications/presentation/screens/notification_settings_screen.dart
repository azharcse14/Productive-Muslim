import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_list_row.dart';
import '../../../../shared/widgets/q_seg_control.dart';
import '../../../../shared/widgets/q_step_button.dart';
import '../../../daily_content/domain/usecases/pick_daily_content.dart';
import '../../../nearby_mosques/domain/external_launcher.dart';
import '../../../settings/domain/entities/notification_matrix.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';
import '../../data/jamaat_focus_bridge.dart';
import '../../domain/repositories/notification_scheduler.dart';
import '../state/notification_controller.dart';

/// Notification matrix (design §12/§15): per-prayer azan/beep/silent/off,
/// sahri & iftar alerts, jamaat reminder + lead, evening muhasaba nudge.
/// Includes permission-denied education and Android exact-alarm guidance —
/// denial never breaks the app.
final class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

final class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final SettingsStore _store = locator<SettingsStore>();
  final NotificationScheduler _scheduler = locator<NotificationScheduler>();
  final NotificationController _controller = locator<NotificationController>();

  final _permission = signal(NotificationPermission.notRequested);
  final _exactAlarms = signal(true);

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Re-check on return from system settings, where the user may have
    // switched notifications on.
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_refreshStatus()),
    );
    unawaited(_refreshStatus());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    _permission.value = await _scheduler.permissionStatus();
    _exactAlarms.value = await _scheduler.canScheduleExactAlarms();
  }

  /// Always try the OS prompt first (on iOS the Settings row only exists
  /// once the app has asked). Fall through to system settings only when
  /// the user had already been prompted and is still denied — the OS won't
  /// show the prompt again. A user who just tapped "Don't allow" on their
  /// first prompt stays here ([permissionStatus] reports never-prompted as
  /// [NotificationPermission.notRequested]).
  Future<void> _requestPermission() async {
    final wasDenied = _permission.value == NotificationPermission.denied;
    final result = await _scheduler.requestPermission();
    _permission.value = result;
    if (wasDenied && result == NotificationPermission.denied) {
      await _scheduler.openSystemSettings();
    }
  }

  NotificationMatrix get _matrix => _store.settings.value.notifications;

  String _formatMinuteOfDay(BuildContext context, int minuteOfDay) {
    final locale = Localizations.localeOf(context);
    final dt = DateTime(2000, 1, 1, minuteOfDay ~/ 60, minuteOfDay % 60);
    return LocaleDigits.localize(
      DateFormat.jm(locale.toString()).format(dt),
      locale.languageCode,
    );
  }

  String _scheduledUntilText(BuildContext context) {
    final until = _controller.scheduledUntil.value;
    if (until == null) {
      return context.l10n.notifScheduledNone;
    }
    final locale = Localizations.localeOf(context);
    final when = LocaleDigits.localize(
      DateFormat.MMMEd(locale.toString()).add_jm().format(until),
      locale.languageCode,
    );
    return context.l10n.notifScheduledUntil(when);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifSettingsTitle)),
      body: SignalBuilder(
        builder: (context) {
          final matrix = _matrix;
          return ListView(
            padding: const EdgeInsets.all(QSpace.s5),
            children: [
              if (_permission.value == NotificationPermission.denied) ...[
                QBanner(
                  text: l10n.notifPermissionDeniedBanner,
                  icon: Icons.notifications_off_outlined,
                  tone: q.warnSoft,
                  foreground: q.warn,
                ),
                const SizedBox(height: QSpace.s3),
              ],
              if (_permission.value != NotificationPermission.granted) ...[
                QButton(
                  label: l10n.notifEnableCta,
                  kind: QButtonKind.tonal,
                  icon: Icons.notifications_active_outlined,
                  expand: true,
                  onPressed: () => unawaited(_requestPermission()),
                ),
                const SizedBox(height: QSpace.s5),
              ],
              if (!_exactAlarms.value) ...[
                QBanner(
                  text: l10n.notifExactAlarmBanner,
                  icon: Icons.alarm_outlined,
                ),
                const SizedBox(height: QSpace.s2),
                QButton(
                  label: l10n.notifExactAlarmCta,
                  kind: QButtonKind.ghost,
                  small: true,
                  onPressed: () => unawaited(
                    _scheduler.requestExactAlarmPermission().then(
                      (_) => _refreshStatus(),
                    ),
                  ),
                ),
                const SizedBox(height: QSpace.s4),
              ],
              Text(
                l10n.notifPerPrayerHeader.toUpperCase(),
                style: context.text.labelSmall,
              ),
              const SizedBox(height: QSpace.s3),
              QCard(
                padding: const EdgeInsets.all(QSpace.s4),
                child: Column(
                  children: [
                    for (final prayer in Prayer.values) ...[
                      Row(
                        children: [
                          SizedBox(
                            width: 76,
                            child: Text(
                              l10n.prayerLabel(prayer),
                              style: QType.titleSm.copyWith(color: q.ink),
                            ),
                          ),
                          Expanded(
                            child: QSegControl(
                              options: [
                                l10n.azanModeAzan,
                                l10n.azanModeBeep,
                                l10n.azanModeSilent,
                                l10n.azanModeOff,
                              ],
                              activeIndex: matrix.modeFor(prayer).index,
                              onChanged: (i) => unawaited(
                                _store.setNotifications(
                                  matrix.copyWith(
                                    prayerModes: {
                                      ...matrix.prayerModes,
                                      prayer: AzanMode.values[i],
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (prayer != Prayer.values.last)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: QSpace.s2),
                          child: Divider(),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: QSpace.s5),
              QCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: QSpace.s4,
                  vertical: QSpace.s1,
                ),
                child: Column(
                  children: [
                    QListRow(
                      icon: Icons.nightlight_outlined,
                      title: l10n.notifSahriToggle,
                      subtitle: l10n.notifSahriToggleSub,
                      trailing: Switch(
                        value: matrix.sahriAlert,
                        onChanged: (v) => unawaited(
                          _store.setNotifications(
                            matrix.copyWith(sahriAlert: v),
                          ),
                        ),
                      ),
                    ),
                    if (matrix.sahriAlert)
                      _LeadRow(
                        label: l10n.leadTimeLabel,
                        minutes: matrix.sahriLead.inMinutes,
                        onChanged: (m) => unawaited(
                          _store.setNotifications(
                            matrix.copyWith(sahriLead: Duration(minutes: m)),
                          ),
                        ),
                      ),
                    const Divider(),
                    QListRow(
                      icon: Icons.wb_twilight_outlined,
                      title: l10n.notifIftarToggle,
                      subtitle: l10n.notifIftarToggleSub,
                      trailing: Switch(
                        value: matrix.iftarAlert,
                        onChanged: (v) => unawaited(
                          _store.setNotifications(
                            matrix.copyWith(iftarAlert: v),
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                    QListRow(
                      icon: Icons.groups_outlined,
                      title: l10n.notifJamaatToggle,
                      subtitle: l10n.notifJamaatToggleSub,
                      trailing: Switch(
                        value: matrix.jamaatReminder,
                        onChanged: (v) => unawaited(
                          _store.setNotifications(
                            matrix.copyWith(jamaatReminder: v),
                          ),
                        ),
                      ),
                    ),
                    if (matrix.jamaatReminder)
                      _LeadRow(
                        label: l10n.leadTimeLabel,
                        minutes: matrix.jamaatLead.inMinutes,
                        onChanged: (m) => unawaited(
                          _store.setNotifications(
                            matrix.copyWith(jamaatLead: Duration(minutes: m)),
                          ),
                        ),
                      ),
                    const Divider(),
                    QListRow(
                      icon: Icons.favorite_outline,
                      title: l10n.notifMuhasabaToggle,
                      subtitle: l10n.notifMuhasabaToggleSub,
                      trailing: Switch(
                        value: matrix.muhasabaEveningReminder,
                        onChanged: (v) => unawaited(
                          _store.setNotifications(
                            matrix.copyWith(muhasabaEveningReminder: v),
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                    QListRow(
                      icon: Icons.auto_stories_outlined,
                      title: l10n.notifDailyToggle,
                      subtitle: l10n.notifDailyToggleSub,
                      trailing: Switch(
                        value: matrix.dailyReminder,
                        onChanged: (v) => unawaited(
                          _store.setNotifications(
                            matrix.copyWith(dailyReminder: v),
                          ),
                        ),
                      ),
                    ),
                    if (matrix.dailyReminder) ...[
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 52,
                          bottom: QSpace.s2,
                        ),
                        child: QSegControl(
                          options: [
                            l10n.notifDailyKindHadith,
                            l10n.notifDailyKindDua,
                          ],
                          activeIndex:
                              matrix.dailyReminderKind == DailyContentKind.dua
                              ? 1
                              : 0,
                          onChanged: (i) => unawaited(
                            _store.setNotifications(
                              matrix.copyWith(
                                dailyReminderKind: i == 1
                                    ? DailyContentKind.dua
                                    : DailyContentKind.hadith,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _TimeRow(
                        label: l10n.notifDailyTimeLabel,
                        minuteOfDay: matrix.dailyReminderMinute,
                        formatMinuteOfDay: (m) =>
                            _formatMinuteOfDay(context, m),
                        onChanged: (m) => unawaited(
                          _store.setNotifications(
                            matrix.copyWith(dailyReminderMinute: m),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: QSpace.s5),
              _JamaatFocusCard(store: _store),
              const SizedBox(height: QSpace.s4),
              QBanner(
                text: _scheduledUntilText(context),
                icon: Icons.event_available_outlined,
                tone: q.surface2,
                foreground: q.ink2,
              ),
              const SizedBox(height: QSpace.s2),
              QBanner(
                text: l10n.notifBatteryHint,
                icon: Icons.battery_saver_outlined,
                tone: q.surface2,
                foreground: q.ink2,
              ),
              const SizedBox(height: QSpace.s10),
            ],
          );
        },
      ),
    );
  }
}

final class _LeadRow extends StatelessWidget {
  const _LeadRow({
    required this.label,
    required this.minutes,
    required this.onChanged,
    this.min = 5,
    this.max = 60,
    this.zeroLabel,
  });

  final String label;
  final int minutes;
  final ValueChanged<int>? onChanged;
  final int min;
  final int max;

  /// Shown instead of "0 min" (e.g. "When I end it").
  final String? zeroLabel;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 52, bottom: QSpace.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: QType.caption.copyWith(color: q.ink2)),
          ),
          QStepButton(
            fill: context.q.surface2,
            size: 32,
            icon: Icons.remove,
            semanticLabel: context.l10n.a11yDecrease(label),
            onTap: onChanged != null && minutes > min
                ? () => onChanged!(minutes - 5)
                : null,
          ),
          SizedBox(
            width: zeroLabel == null ? 64 : 96,
            child: Text(
              minutes == 0 && zeroLabel != null
                  ? zeroLabel!
                  : context.l10n.minutesShort(minutes),
              textAlign: TextAlign.center,
              style: QType.num_(QType.label).copyWith(color: q.ink),
            ),
          ),
          QStepButton(
            fill: context.q.surface2,
            size: 32,
            icon: Icons.add,
            semanticLabel: context.l10n.a11yIncrease(label),
            onTap: onChanged != null && minutes < max
                ? () => onChanged!(minutes + 5)
                : null,
          ),
        ],
      ),
    );
  }
}

/// A stepper row for a wall-clock time stored as minutes past midnight.
/// Steps by 15 minutes, wrapping across midnight, mirroring [_LeadRow].
final class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.minuteOfDay,
    required this.formatMinuteOfDay,
    required this.onChanged,
  });

  final String label;
  final int minuteOfDay;
  final String Function(int) formatMinuteOfDay;
  final ValueChanged<int> onChanged;

  static const _step = 15;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    int wrap(int m) => (m + 24 * 60) % (24 * 60);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 52, bottom: QSpace.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: QType.caption.copyWith(color: q.ink2)),
          ),
          QStepButton(
            fill: context.q.surface2,
            size: 32,
            icon: Icons.remove,
            semanticLabel: context.l10n.a11yDecrease(label),
            onTap: () => onChanged(wrap(minuteOfDay - _step)),
          ),
          // ±15 nudges; tapping the time jumps anywhere via the picker.
          InkWell(
            borderRadius: BorderRadius.circular(QRadius.sm),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: minuteOfDay ~/ 60,
                  minute: minuteOfDay % 60,
                ),
              );
              if (picked != null) {
                onChanged(picked.hour * 60 + picked.minute);
              }
            },
            child: SizedBox(
              width: 84,
              height: QTouch.minTarget,
              child: Center(
                child: Text(
                  formatMinuteOfDay(minuteOfDay),
                  textAlign: TextAlign.center,
                  style: QType.num_(QType.label).copyWith(color: q.primary),
                ),
              ),
            ),
          ),
          QStepButton(
            fill: context.q.surface2,
            size: 32,
            icon: Icons.add,
            semanticLabel: context.l10n.a11yIncrease(label),
            onTap: () => onChanged(wrap(minuteOfDay + _step)),
          ),
        ],
      ),
    );
  }
}

/// Jamaat focus: silence (+ lock) the phone around jamaat. Android does it
/// natively (DND + accessibility app block); iOS only gets a nudge, since
/// no iOS app may silence or lock the phone.
final class _JamaatFocusCard extends StatefulWidget {
  const _JamaatFocusCard({required this.store});

  final SettingsStore store;

  @override
  State<_JamaatFocusCard> createState() => _JamaatFocusCardState();
}

final class _JamaatFocusCardState extends State<_JamaatFocusCard> {
  static const _bridge = JamaatFocusBridge();
  final _android = defaultTargetPlatform == TargetPlatform.android;

  final _status = signal<FocusStatus>((
    active: false,
    strict: false,
    nafs: false,
    until: null,
  ));
  final _canSilence = signal(true);
  final _canBlock = signal(true);
  late final AppLifecycleListener _lifecycle;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // Back from the DND / accessibility settings pages.
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_refresh()));
    unawaited(_refresh());
    // A session can start or end (alarm, shake) while this screen is open.
    if (_android) {
      _poll = Timer.periodic(
        const Duration(seconds: 15),
        (_) => unawaited(_refresh()),
      );
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!_android) {
      return;
    }
    try {
      _status.value = await _bridge.status();
      _canSilence.value = await _bridge.hasSilencePermission();
      _canBlock.value = await _bridge.hasBlockPermission();
    } on Object catch (_) {
      // No native side (tests, other platforms): stay on the defaults.
    }
  }

  NotificationMatrix get _matrix => widget.store.settings.value.notifications;

  void _set(NotificationMatrix m) =>
      unawaited(widget.store.setNotifications(m));

  Future<void> _requestBlock() async {
    final l10n = context.l10n;
    // Play policy: prominent disclosure before the accessibility settings.
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.focusDisclosureTitle),
        content: Text(l10n.focusDisclosureBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.focusContinue),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await _bridge.requestBlockPermission();
    }
  }

  String _time(BuildContext context, DateTime at) {
    final locale = Localizations.localeOf(context);
    return LocaleDigits.localize(
      DateFormat.jm(locale.toString()).format(at),
      locale.languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return SignalBuilder(
      builder: (context) {
        final m = _matrix;
        final status = _status.value;
        // Strict session running: everything frozen until it ends.
        final locked = status.active && status.strict;
        final void Function(NotificationMatrix)? set = locked ? null : _set;
        Widget permission(String text, Future<void> Function() request) =>
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 52,
                bottom: QSpace.s2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: QType.caption.copyWith(color: q.warn),
                    ),
                  ),
                  QButton(
                    label: l10n.focusAllow,
                    kind: QButtonKind.ghost,
                    small: true,
                    onPressed: () => unawaited(request()),
                  ),
                ],
              ),
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.focusHeader.toUpperCase(),
              style: context.text.labelSmall,
            ),
            const SizedBox(height: QSpace.s3),
            if (status.active && !status.nafs) ...[
              QBanner(
                text: [
                  if (status.until case final until?)
                    l10n.focusActiveUntil(_time(context, until))
                  else
                    l10n.focusActive,
                  if (locked) l10n.focusStrictLocked,
                ].join('\n'),
                icon: locked ? Icons.lock_outline : Icons.do_not_disturb_on,
              ),
              if (!locked)
                QButton(
                  label: l10n.focusEndNow,
                  kind: QButtonKind.ghost,
                  small: true,
                  onPressed: () =>
                      unawaited(_bridge.end().then((_) => _refresh())),
                ),
              const SizedBox(height: QSpace.s3),
            ],
            QCard(
              padding: const EdgeInsets.symmetric(
                horizontal: QSpace.s4,
                vertical: QSpace.s1,
              ),
              child: Column(
                children: [
                  QListRow(
                    icon: Icons.do_not_disturb_on_outlined,
                    title: l10n.focusToggle,
                    subtitle: _android
                        ? l10n.focusToggleSub
                        : l10n.focusToggleSubIos,
                    trailing: Switch(
                      value: m.jamaatFocus,
                      onChanged: set == null
                          ? null
                          : (v) {
                              set(m.copyWith(jamaatFocus: v));
                              if (v && _android && !_canSilence.value) {
                                unawaited(_bridge.requestSilencePermission());
                              }
                            },
                    ),
                  ),
                  if (!_android) ...[
                    const Divider(),
                    QListRow(
                      icon: Icons.auto_awesome_outlined,
                      title: l10n.shortcutsGuideRow,
                      subtitle: l10n.shortcutsGuideRowSub,
                      onTap: () => unawaited(_showShortcutsGuide(context)),
                    ),
                  ],
                  if (m.jamaatFocus) ...[
                    if (_android && !_canSilence.value)
                      permission(
                        l10n.focusPermSilence,
                        _bridge.requestSilencePermission,
                      ),
                    _LeadRow(
                      label: l10n.focusLeadLabel,
                      minutes: m.jamaatFocusLead.inMinutes,
                      min: 0,
                      max: 30,
                      onChanged: set == null
                          ? null
                          : (v) => set(
                              m.copyWith(jamaatFocusLead: Duration(minutes: v)),
                            ),
                    ),
                    _LeadRow(
                      label: l10n.focusDurationLabel,
                      minutes: m.jamaatFocusDuration.inMinutes,
                      // Strict always ends on its own (see copyWith).
                      min: m.jamaatFocusStrict ? 5 : 0,
                      max: 90,
                      zeroLabel: l10n.focusDurationManual,
                      onChanged: set == null
                          ? null
                          : (v) => set(
                              m.copyWith(
                                jamaatFocusDuration: Duration(minutes: v),
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 52,
                        bottom: QSpace.s2,
                      ),
                      child: Wrap(
                        spacing: QSpace.s2,
                        children: [
                          for (final prayer in Prayer.values)
                            FilterChip(
                              label: Text(l10n.prayerLabel(prayer)),
                              selected: m.jamaatFocusPrayers.contains(prayer),
                              onSelected: set == null
                                  ? null
                                  : (on) => set(
                                      m.copyWith(
                                        jamaatFocusPrayers: on
                                            ? {...m.jamaatFocusPrayers, prayer}
                                            : ({...m.jamaatFocusPrayers}
                                                ..remove(prayer)),
                                      ),
                                    ),
                            ),
                        ],
                      ),
                    ),
                    if (_android) ...[
                      const Divider(),
                      QListRow(
                        icon: Icons.phonelink_lock_outlined,
                        title: l10n.focusBlockToggle,
                        subtitle: l10n.focusBlockToggleSub,
                        trailing: Switch(
                          value: m.jamaatFocusBlock,
                          onChanged: set == null
                              ? null
                              : (v) => set(m.copyWith(jamaatFocusBlock: v)),
                        ),
                      ),
                      if (m.jamaatFocusBlock && !_canBlock.value)
                        permission(l10n.focusPermBlock, _requestBlock),
                      const Divider(),
                      QListRow(
                        icon: Icons.lock_outline,
                        title: l10n.focusStrictToggle,
                        subtitle: l10n.focusStrictToggleSub,
                        trailing: Switch(
                          value: m.jamaatFocusStrict,
                          onChanged: set == null
                              ? null
                              : (v) => set(m.copyWith(jamaatFocusStrict: v)),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            // Nafs lock: shake detection needs the Android accessibility
            // service; iOS gives apps no way to lock the phone.
            if (_android) ...[
              const SizedBox(height: QSpace.s5),
              Text(
                l10n.nafsHeader.toUpperCase(),
                style: context.text.labelSmall,
              ),
              const SizedBox(height: QSpace.s3),
              if (status.active && status.nafs) ...[
                QBanner(
                  text: [
                    if (status.until case final until?)
                      l10n.nafsActiveUntil(_time(context, until)),
                    l10n.focusStrictLocked,
                  ].join('\n'),
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: QSpace.s3),
              ],
              QCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: QSpace.s4,
                  vertical: QSpace.s1,
                ),
                child: Column(
                  children: [
                    QListRow(
                      icon: Icons.vibration,
                      title: l10n.nafsToggle,
                      subtitle: l10n.nafsToggleSub,
                      trailing: Switch(
                        value: m.nafsLock,
                        onChanged: set == null
                            ? null
                            : (v) {
                                set(m.copyWith(nafsLock: v));
                                if (v && !_canBlock.value) {
                                  unawaited(_requestBlock());
                                }
                              },
                      ),
                    ),
                    if (m.nafsLock) ...[
                      if (!_canBlock.value)
                        permission(l10n.nafsPermBlock, _requestBlock),
                      _LeadRow(
                        label: l10n.nafsDurationLabel,
                        minutes: m.nafsLockDuration.inMinutes,
                        onChanged: set == null
                            ? null
                            : (v) => set(
                                m.copyWith(
                                  nafsLockDuration: Duration(minutes: v),
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// iOS can't be silenced by an app, but the user's own Shortcuts
/// automation can: a step-by-step guide plus a jump into Shortcuts.
Future<void> _showShortcutsGuide(BuildContext context) {
  final l10n = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final q = sheetContext.q;
      Widget header(String text) => Padding(
        padding: const EdgeInsets.only(top: QSpace.s4, bottom: QSpace.s2),
        child: Text(text, style: QType.titleSm.copyWith(color: q.ink)),
      );
      List<Widget> steps(List<String> texts) => [
        for (final (i, text) in texts.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: QSpace.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    LocaleDigits.localize(
                      '${i + 1}.',
                      Localizations.localeOf(sheetContext).languageCode,
                    ),
                    style: QType.caption.copyWith(color: q.primary),
                  ),
                ),
                Expanded(
                  child: Text(
                    text,
                    style: QType.caption.copyWith(color: q.ink2),
                  ),
                ),
              ],
            ),
          ),
      ];
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            QSpace.s5,
            QSpace.s5,
            QSpace.s5,
            QSpace.s4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.shortcutsGuideTitle,
                style: QType.title.copyWith(color: q.ink),
              ),
              const SizedBox(height: QSpace.s2),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      l10n.shortcutsGuideIntro,
                      style: QType.caption.copyWith(color: q.ink2),
                    ),
                    header(l10n.shortcutsMosqueHeader),
                    ...steps([
                      l10n.shortcutsMosqueStep1,
                      l10n.shortcutsMosqueStep2,
                      l10n.shortcutsMosqueStep3,
                      l10n.shortcutsMosqueStep4,
                    ]),
                    header(l10n.shortcutsTimeHeader),
                    ...steps([
                      l10n.shortcutsTimeStep1,
                      l10n.shortcutsTimeStep2,
                      l10n.shortcutsTimeStep3,
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: QSpace.s4),
              QButton(
                label: l10n.shortcutsOpen,
                icon: Icons.open_in_new,
                expand: true,
                onPressed: () => unawaited(
                  locator<ExternalLauncher>().launch(Uri.parse('shortcuts://')),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
