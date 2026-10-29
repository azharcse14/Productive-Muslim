import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
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
import '../../../settings/domain/repositories/zoned_clock.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';
import '../../domain/repositories/jamaat_focus_control.dart';
import '../../domain/repositories/notification_scheduler.dart';
import '../state/notification_controller.dart';

/// Notification matrix (design §12/§15), in headed groups: per-prayer
/// azan/beep/silent/off, Ramadan (sahri & iftar), jamaat reminder + lead,
/// daily reminders, delivery status. Jamaat focus / nafs lock live on their
/// own page ([JamaatFocusSettingsScreen]). Includes permission education
/// and Android exact-alarm guidance — denial never breaks the app.
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

  /// Null until checked, so the "Enable" CTA doesn't flash on first frame.
  final _permission = signal<NotificationPermission?>(null);
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

  static final _android = defaultTargetPlatform == TargetPlatform.android;

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
              if (_permission.value case final p?
                  when p != NotificationPermission.granted) ...[
                // Settings below still save; they just can't be delivered.
                QBanner(
                  text: p == NotificationPermission.denied
                      ? l10n.notifPermissionDeniedBanner
                      : l10n.notifPermissionNotAskedBanner,
                  icon: Icons.notifications_off_outlined,
                  tone: q.warnSoft,
                  foreground: q.warn,
                ),
                const SizedBox(height: QSpace.s3),
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
                      // Name on its own line: a fixed-width label beside a
                      // 4-segment control clipped at large text scales.
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.prayerLabel(prayer),
                            style: QType.titleSm.copyWith(color: q.ink),
                          ),
                          const SizedBox(height: QSpace.s2),
                          QSegControl(
                            semanticsPrefix: l10n.prayerLabel(prayer),
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
              _GroupHeader(l10n.ramadanTitle),
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
                        semanticsName: l10n.notifSahriToggle,
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
                  ],
                ),
              ),
              _GroupHeader(l10n.jamaatLabel),
              QCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: QSpace.s4,
                  vertical: QSpace.s1,
                ),
                child: Column(
                  children: [
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
                        semanticsName: l10n.notifJamaatToggle,
                        minutes: matrix.jamaatLead.inMinutes,
                        onChanged: (m) => unawaited(
                          _store.setNotifications(
                            matrix.copyWith(jamaatLead: Duration(minutes: m)),
                          ),
                        ),
                      ),
                    const Divider(),
                    QListRow(
                      icon: Icons.do_not_disturb_on_outlined,
                      title: _android ? l10n.focusPageTitle : l10n.focusHeader,
                      subtitle: l10n.focusPageRowSub,
                      trailing: Icon(Icons.chevron_right, color: q.ink3),
                      onTap: () => unawaited(
                        context.pushNamed(Routes.notificationFocus.name),
                      ),
                    ),
                  ],
                ),
              ),
              _GroupHeader(l10n.notifGroupDaily),
              QCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: QSpace.s4,
                  vertical: QSpace.s1,
                ),
                child: Column(
                  children: [
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
                      icon: Icons.menu_book_outlined,
                      title: l10n.notifDailyAyahToggle,
                      subtitle: l10n.notifDailyAyahToggleSub,
                      trailing: Switch(
                        value: matrix.dailyAyahReminder,
                        onChanged: (v) => unawaited(
                          _store.setNotifications(
                            matrix.copyWith(dailyAyahReminder: v),
                          ),
                        ),
                      ),
                    ),
                    if (matrix.dailyAyahReminder)
                      _TimeRow(
                        label: l10n.notifDailyTimeLabel,
                        semanticsName: l10n.notifDailyAyahToggle,
                        minuteOfDay: matrix.dailyAyahMinute,
                        formatMinuteOfDay: (m) =>
                            _formatMinuteOfDay(context, m),
                        onChanged: (m) => unawaited(
                          _store.setNotifications(
                            matrix.copyWith(dailyAyahMinute: m),
                          ),
                        ),
                      ),
                    const Divider(),
                    QListRow(
                      icon: Icons.auto_stories_outlined,
                      title: l10n.notifDailyHadithToggle,
                      subtitle: l10n.notifDailyHadithToggleSub,
                      trailing: Switch(
                        value: matrix.dailyHadithReminder,
                        onChanged: (v) => unawaited(
                          _store.setNotifications(
                            matrix.copyWith(dailyHadithReminder: v),
                          ),
                        ),
                      ),
                    ),
                    if (matrix.dailyHadithReminder)
                      _TimeRow(
                        label: l10n.notifDailyTimeLabel,
                        semanticsName: l10n.notifDailyHadithToggle,
                        minuteOfDay: matrix.dailyHadithMinute,
                        formatMinuteOfDay: (m) =>
                            _formatMinuteOfDay(context, m),
                        onChanged: (m) => unawaited(
                          _store.setNotifications(
                            matrix.copyWith(dailyHadithMinute: m),
                          ),
                        ),
                      ),
                    const Divider(),
                    QListRow(
                      icon: Icons.today_outlined,
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
                        semanticsName: l10n.notifDailyToggle,
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
              _GroupHeader(l10n.notifGroupDelivery),
              QBanner(
                text: _scheduledUntilText(context),
                icon: Icons.event_available_outlined,
                tone: q.surface2,
                foreground: q.ink2,
              ),
              // Battery optimization is an Android-only setting.
              if (defaultTargetPlatform == TargetPlatform.android) ...[
                const SizedBox(height: QSpace.s2),
                QBanner(
                  text: l10n.notifBatteryHint,
                  icon: Icons.battery_saver_outlined,
                  tone: q.surface2,
                  foreground: q.ink2,
                ),
              ],
              const SizedBox(height: QSpace.s10),
            ],
          );
        },
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
      top: QSpace.s5,
      bottom: QSpace.s3,
      start: QSpace.s1,
    ),
    child: Text(title.toUpperCase(), style: context.text.labelSmall),
  );
}

/// Jamaat focus + nafs lock, split off the main notification settings so
/// the alert matrix stays scannable.
final class JamaatFocusSettingsScreen extends StatelessWidget {
  const JamaatFocusSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          defaultTargetPlatform == TargetPlatform.android
              ? l10n.focusPageTitle
              : l10n.focusHeader,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(QSpace.s5),
        children: [
          _JamaatFocusCard(
            store: locator<SettingsStore>(),
            focus: locator<JamaatFocusControl>(),
          ),
          const SizedBox(height: QSpace.s10),
        ],
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
    this.semanticsName,
  });

  final String label;

  /// What this lead is for (e.g. "Sahri warning"), so screen readers can
  /// tell several "Lead time" rows apart.
  final String? semanticsName;
  final int minutes;
  final ValueChanged<int>? onChanged;
  final int min;
  final int max;

  /// Shown instead of "0 min" (e.g. "When I end it").
  final String? zeroLabel;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final a11y = semanticsName == null ? label : '$semanticsName $label';
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 52, bottom: QSpace.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              semanticsLabel: a11y,
              style: QType.caption.copyWith(color: q.ink2),
            ),
          ),
          QStepButton(
            fill: context.q.surface2,
            size: 32,
            icon: Icons.remove,
            semanticLabel: context.l10n.a11yDecrease(a11y),
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
            semanticLabel: context.l10n.a11yIncrease(a11y),
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
    this.semanticsName,
  });

  final String label;

  /// See [_LeadRow.semanticsName].
  final String? semanticsName;
  final int minuteOfDay;
  final String Function(int) formatMinuteOfDay;
  final ValueChanged<int> onChanged;

  static const _step = 15;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final a11y = semanticsName == null ? label : '$semanticsName $label';
    int wrap(int m) => (m + 24 * 60) % (24 * 60);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 52, bottom: QSpace.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              semanticsLabel: a11y,
              style: QType.caption.copyWith(color: q.ink2),
            ),
          ),
          QStepButton(
            fill: context.q.surface2,
            size: 32,
            icon: Icons.remove,
            semanticLabel: context.l10n.a11yDecrease(a11y),
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
            semanticLabel: context.l10n.a11yIncrease(a11y),
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
  const _JamaatFocusCard({required this.store, required this.focus});

  final SettingsStore store;
  final JamaatFocusControl focus;

  @override
  State<_JamaatFocusCard> createState() => _JamaatFocusCardState();
}

final class _JamaatFocusCardState extends State<_JamaatFocusCard> {
  final _android = defaultTargetPlatform == TargetPlatform.android;

  final _status = signal<FocusStatus>((
    active: false,
    strict: false,
    nafs: false,
    until: null,
  ));
  final _canSilence = signal(true);
  final _canBlock = signal(true);

  /// False in a `focusBlocking=false` build: no lock / nafs lock UI at all.
  final _blockingAvailable = signal(true);
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
      _blockingAvailable.value = await widget.focus.isBlockingAvailable();
      _status.value = await widget.focus.status(
        toWall: (instant) => switch (widget.store.location.value) {
          final location? => locator<ZonedClock>().instantAt(location, instant),
          null => instant.toLocal(),
        },
      );
      _canSilence.value = await widget.focus.hasSilencePermission();
      _canBlock.value = await widget.focus.hasBlockPermission();
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
      await widget.focus.requestBlockPermission();
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
        final canLock = _android && _blockingAvailable.value;
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
                      unawaited(widget.focus.end().then((_) => _refresh())),
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
                    title: !_android || canLock
                        ? l10n.focusToggle
                        : l10n.focusToggleSilentOnly,
                    subtitle: !_android
                        ? l10n.focusToggleSubIos
                        : canLock
                        ? l10n.focusToggleSub
                        : l10n.focusToggleSubSilentOnly,
                    trailing: Switch(
                      value: m.jamaatFocus,
                      onChanged: set == null
                          ? null
                          : (v) {
                              set(m.copyWith(jamaatFocus: v));
                              if (v && _android && !_canSilence.value) {
                                unawaited(
                                  widget.focus.requestSilencePermission(),
                                );
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
                        widget.focus.requestSilencePermission,
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
                    if (canLock) ...[
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
                    ],
                    if (_android) ...[
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
            if (canLock) ...[
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
                onPressed: () => unawaited(_openShortcuts(sheetContext)),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// When iOS refuses `shortcuts://` (app deleted / restricted) the guide
/// is moot: close the sheet so the snackbar isn't hidden under it.
Future<void> _openShortcuts(BuildContext sheetContext) async {
  final navigator = Navigator.of(sheetContext);
  final messenger = ScaffoldMessenger.of(sheetContext);
  final message = sheetContext.l10n.shortcutsOpenFailed;
  if (!await locator<ExternalLauncher>().launch(Uri.parse('shortcuts://'))) {
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
