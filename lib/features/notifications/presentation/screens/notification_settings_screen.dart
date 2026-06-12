import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_list_row.dart';
import '../../../../shared/widgets/q_seg_control.dart';
import '../../../settings/domain/entities/notification_matrix.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';
import '../../domain/repositories/notification_scheduler.dart';

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

  final _permission = signal(NotificationPermission.notRequested);
  final _exactAlarms = signal(true);

  @override
  void initState() {
    super.initState();
    unawaited(_refreshStatus());
  }

  Future<void> _refreshStatus() async {
    _permission.value = await _scheduler.permissionStatus();
    _exactAlarms.value = await _scheduler.canScheduleExactAlarms();
  }

  Future<void> _requestPermission() async {
    _permission.value = await _scheduler.requestPermission();
  }

  NotificationMatrix get _matrix => _store.settings.value.notifications;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifSettingsTitle)),
      body: SignalBuilder(builder: (context) {
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
                  _scheduler
                      .requestExactAlarmPermission()
                      .then((_) => _refreshStatus()),
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
                        _store
                            .setNotifications(matrix.copyWith(sahriAlert: v)),
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
                        _store
                            .setNotifications(matrix.copyWith(iftarAlert: v)),
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
                ],
              ),
            ),
            const SizedBox(height: QSpace.s4),
            QBanner(
              text: l10n.notifBatteryHint,
              icon: Icons.battery_saver_outlined,
              tone: q.surface2,
              foreground: q.ink2,
            ),
            const SizedBox(height: QSpace.s10),
          ],
        );
      }),
    );
  }
}

final class _LeadRow extends StatelessWidget {
  const _LeadRow({
    required this.label,
    required this.minutes,
    required this.onChanged,
  });

  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 52,
        bottom: QSpace.s2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: QType.caption.copyWith(color: q.ink2)),
          ),
          _StepButton(
            icon: Icons.remove,
            onTap: minutes > 5 ? () => onChanged(minutes - 5) : null,
          ),
          SizedBox(
            width: 64,
            child: Text(
              context.l10n.minutesShort(minutes),
              textAlign: TextAlign.center,
              style: QType.num_(QType.label).copyWith(color: q.ink),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            onTap: minutes < 60 ? () => onChanged(minutes + 5) : null,
          ),
        ],
      ),
    );
  }
}

final class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return InkWell(
      borderRadius: BorderRadius.circular(QRadius.full),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: q.surface2, shape: BoxShape.circle),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? q.ink3 : q.ink,
        ),
      ),
    );
  }
}
