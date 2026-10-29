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
import '../../../prayer_times/presentation/screens/home_formatting.dart';
import '../../../prayer_times/presentation/state/home_store.dart';
import '../../../settings/domain/entities/notification_matrix.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';

/// Screen listing daily scheduled notifications and reminders.
/// Appbar settings icon routes to [NotificationSettingsScreen].
final class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

final class _NotificationsScreenState extends State<NotificationsScreen> {
  late final HomeStore? _homeStore = locator.isRegistered<HomeStore>()
      ? locator<HomeStore>()
      : null;
  late final SettingsStore _settings = locator<SettingsStore>();

  String _formatTime(BuildContext context, DateTime time) {
    return formatHomeTime(context, time);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          IconButton(
            tooltip: l10n.notifSettingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                unawaited(context.pushNamed(Routes.notificationSettings.name)),
          ),
        ],
      ),
      body: SignalBuilder(
        builder: (context) {
          final matrix = _settings.settings.value.notifications;
          final home = _homeStore;
          final day = home?.prayerDay.value;

          final items = <_NotificationViewItem>[];

          if (day != null) {
            const icons = {
              Prayer.fajr: Icons.mosque_outlined,
              Prayer.dhuhr: Icons.wb_sunny_outlined,
              Prayer.asr: Icons.wb_twilight_outlined,
              Prayer.maghrib: Icons.nightlight_round_outlined,
              Prayer.isha: Icons.bedtime_outlined,
            };
            for (final prayer in Prayer.values) {
              if (matrix.modeFor(prayer) == AzanMode.off) {
                continue;
              }
              final name = l10n.prayerLabel(prayer);
              final time = _formatTime(context, day.startOf(prayer));
              items.add(
                _NotificationViewItem(
                  icon: icons[prayer]!,
                  title: l10n.notifAzanTitle(name, time),
                  subtitle: l10n.notifAzanBody(name),
                  time: time,
                  route: '/home',
                ),
              );
            }
          }

          if (matrix.dailyAyahReminder) {
            final now = DateTime.now();
            final t = DateTime(
              now.year,
              now.month,
              now.day,
              matrix.dailyAyahMinute ~/ 60,
              matrix.dailyAyahMinute % 60,
            );
            items.add(
              _NotificationViewItem(
                icon: Icons.menu_book_outlined,
                title: l10n.notifDailyAyahTitle,
                subtitle: l10n.notifDailyAyahBody,
                time: _formatTime(context, t),
                route: '/home',
              ),
            );
          }

          if (matrix.dailyHadithReminder) {
            final now = DateTime.now();
            final t = DateTime(
              now.year,
              now.month,
              now.day,
              matrix.dailyHadithMinute ~/ 60,
              matrix.dailyHadithMinute % 60,
            );
            items.add(
              _NotificationViewItem(
                icon: Icons.auto_stories_outlined,
                title: l10n.notifDailyHadithTitle,
                subtitle: l10n.notifDailyHadithBody,
                time: _formatTime(context, t),
                route: '/hadith',
              ),
            );
          }

          if (matrix.muhasabaEveningReminder && day != null) {
            items.add(
              _NotificationViewItem(
                icon: Icons.favorite_outline,
                title: l10n.notifMuhasabaTitle,
                subtitle: l10n.notifMuhasabaBody,
                // Same moment the plan fires it: isha + 45 min.
                time: _formatTime(
                  context,
                  day.isha.add(const Duration(minutes: 45)),
                ),
                route: '/muhasaba',
              ),
            );
          }

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(QSpace.s6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_outlined,
                      size: 64,
                      color: q.ink3,
                    ),
                    const SizedBox(height: QSpace.s4),
                    Text(
                      l10n.notificationsEmptyTitle,
                      style: QType.title,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: QSpace.s2),
                    Text(
                      l10n.notificationsEmptySub,
                      style: QType.caption.copyWith(color: q.ink2),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(QSpace.s5),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: QSpace.s3),
            itemBuilder: (context, index) {
              final item = items[index];
              return QCard(
                onTap: () => context.go(item.route),
                padding: const EdgeInsets.all(QSpace.s4),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: q.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: q.primary, size: 22),
                    ),
                    const SizedBox(width: QSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: QType.label.copyWith(
                              fontVariations: const [
                                FontVariation('wght', 600),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: QType.caption.copyWith(color: q.ink2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: QSpace.s2),
                    Text(
                      item.time,
                      style: QType.caption.copyWith(
                        color: q.primary,
                        fontVariations: const [FontVariation('wght', 600)],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

final class _NotificationViewItem {
  const _NotificationViewItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final String route;
}
